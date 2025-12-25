

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}



data "aws_caller_identity" "current" {} # used for accessing Account ID and ARN

# render Admin & Developer users list with the structure required by EKS module
locals {
  cluster_name = "${var.name_prefix}-${var.environment}"

  autoscaler_service_account_namespace = "kube-system"
  autoscaler_service_account_name      = "cluster-autoscaler-aws"

  admin_user_map_users = [
    for admin_user in var.admin_users :
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${admin_user}"
      username = admin_user
      groups   = ["system:masters"]
    }
  ]

  developer_user_map_users = [
    for developer_user in var.developer_users :
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${developer_user}"
      username = developer_user
      groups   = ["${var.name_prefix}-developers"]
    }
  ]
}

# reserve Elastic IP to be used in our NAT gateway
resource "aws_eip" "nat_gw_elastic_ip" {
  tags = {
    Name        = "${local.cluster_name}-nat-eip"
    Terraform   = "true"
    Environment = "test"
  }
}

module "ebs_csi_irsa_role" {
  source = "./modules/iam/modules/iam-role-for-service-accounts"

  name = "${local.cluster_name}-ebs-csi-"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}

module "eks" {
  source  = "./modules/eks"

  cluster_name                   = local.cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  create_cloudwatch_log_group = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_8443_tcp = {
      description                = "Node groups to cluster API via port 8443"
      protocol                   = "tcp"
      from_port                  = 8443
      to_port                    = 8443
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    system = {
      min_size     = 1
      max_size     = 3
      desired_size = 1
      ami_type     = "AL2_x86_64"

      instance_types = var.asg_sys_instance_types

      labels = {
        Environment = "test"
      }
      tags = {
        Terraform   = "true"
        Environment = "test"
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}

resource "time_sleep" "wait_for_cluster" {
  depends_on = [module.eks]

  create_duration = "3m"
}

module "eks_auth" {
  source = "./modules/eks-auth"
  depends_on = [time_sleep.wait_for_cluster]

  providers = {
    kubernetes = kubernetes
  }

  eks        = module.eks
  aws_region = var.region

  # map developer & admin ARNs as kubernetes Users
  map_users = concat(local.admin_user_map_users, local.developer_user_map_users)
}

# Create IAM role + automatically make it available to cluster autoscaler service account
module "iam_assumable_role_admin" {
  source                        = "./modules/iam/modules/iam-role-for-service-accounts"
  name                          = "${local.cluster_name}-cluster-autoscaler"
  policies                      = {
    "cluster_autoscaler_policy" = aws_iam_policy.cluster_autoscaler.arn
  }
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.autoscaler_service_account_namespace}:${local.autoscaler_service_account_name}"]
    }
  }

  tags = {
    Owner           = split("/", data.aws_caller_identity.current.arn)[1]
    AutoTag_Creator = data.aws_caller_identity.current.arn
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name_prefix = "${local.cluster_name}-cluster-autoscaler"
  description = "EKS cluster-autoscaler policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    sid    = "clusterAutoscalerAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "clusterAutoscalerOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "helm_release" "cluster-autoscaler" {
  depends_on = [module.eks_auth]
  name             = "cluster-autoscaler"
  namespace        = local.autoscaler_service_account_namespace
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.10.7"
  create_namespace = false

  set {
    name  = "cloudProvider"
    value = "aws"
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = local.autoscaler_service_account_name
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_admin.arn
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "autoDiscovery.enabled"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  set {
    name  = "extraArgs.scale-down-enabled"
    value = "true"
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "5m"
  }
}
