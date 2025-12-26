locals {
  merged_map_roles = distinct(concat(
    try(yamldecode(yamldecode(var.eks.aws_auth_configmap_yaml).data.mapRoles), []),
    var.map_roles,
  ))

  aws_auth_configmap_yaml = templatefile("${path.module}/templates/aws_auth_cm.tpl",
    {
      map_roles    = local.merged_map_roles
      map_users    = var.map_users
      map_accounts = var.map_accounts
    }
  )
}



resource "null_resource" "kubectl_aws_auth_configmap_apply" {
  

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      # Generate a temporary kubeconfig to interact with the EKS cluster
      aws eks update-kubeconfig --name ${var.eks.cluster_name} --region ${var.aws_region} --kubeconfig /tmp/kubeconfig-${var.eks.cluster_name}

      # Set KUBECONFIG environment variable for kubectl
      export KUBECONFIG=/tmp/kubeconfig-${var.eks.cluster_name}
      
      # Create a temporary file for the aws-auth ConfigMap content
      AUTH_CM_FILE=$(mktemp)
      echo '${local.aws_auth_configmap_yaml}' > $AUTH_CM_FILE

      # Apply the ConfigMap using kubectl, handling existing resource gracefully
      kubectl apply -f $AUTH_CM_FILE --server-side --force-conflicts || true

      # Clean up the temporary file
      rm $AUTH_CM_FILE
      rm /tmp/kubeconfig-${var.eks.cluster_name}
    EOT
    interpreter = ["bash", "-c"]
  }
}

