#!/bin/bash
# Script to update Terraform configuration to use local modules

set -e

echo "🔧 Updating Terraform configuration to use local modules..."

# Backup original files
cp vpc.tf vpc.tf.backup
cp eks.tf eks.tf.backup

# Update VPC module to use local source
sed -i 's|source  = "terraform-aws-modules/vpc/aws"|source  = "../vpc"|g' vpc.tf

# Update EKS module to use local source
sed -i 's|source  = "terraform-aws-modules/eks/aws"|source  = "../eks"|g' eks.tf

# Update EBS CSI role module to use local source
sed -i 's|source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-iam"|source = "../../iam/modules/iam-role-for-service-accounts-iam"|g' eks.tf

# Update IAM assumable role module to use local source
sed -i 's|source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"|source                        = "../../iam/modules/iam-assumable-role-with-oidc"|g' eks.tf

# Update EKS auth module to use local source
sed -i 's|source = "aidanmelen/eks-auth/aws"|source = "../eks-auth"|g' eks.tf

echo "✅ Module sources updated successfully!"
echo ""
echo "🚀 Now run: terraform init"
