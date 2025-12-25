module "vpc" {
  source  = "./modules/vpc"

  name = "${local.cluster_name}-vpc"
  cidr = var.main_network_block
  azs  = data.aws_availability_zones.available.names

  private_subnets = ["10.0.32.0/20", "10.0.48.0/20"]

  public_subnets = ["10.0.160.0/20", "10.0.176.0/20"]

  enable_nat_gateway           = true
  single_nat_gateway           = true
  one_nat_gateway_per_az       = false
  create_database_subnet_group = false
  enable_dns_hostnames         = true
  reuse_nat_ips                = true
  external_nat_ip_ids          = [aws_eip.nat_gw_elastic_ip.id]

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}
