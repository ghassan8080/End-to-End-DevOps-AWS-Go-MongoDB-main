#!/bin/bash
# Script to manually download Terraform modules when registry is blocked

set -e

echo "🔧 Downloading Terraform modules manually..."

# Create modules directory
mkdir -p modules

# Download VPC module
echo "📦 Downloading VPC module..."
if [ ! -d "modules/vpc" ]; then
    git clone --depth 1 --branch v5.7.2 https://github.com/terraform-aws-modules/terraform-aws-vpc.git modules/vpc
else
    echo "✅ VPC module already exists"
fi

# Download EKS module
echo "📦 Downloading EKS module..."
if [ ! -d "modules/eks" ]; then
    git clone --depth 1 --branch v20.0.0 https://github.com/terraform-aws-modules/terraform-aws-eks.git modules/eks
else
    echo "✅ EKS module already exists"
fi

# Download IAM module
echo "📦 Downloading IAM module..."
if [ ! -d "modules/iam" ]; then
    git clone --depth 1 --branch v6.2.3 https://github.com/terraform-aws-modules/terraform-aws-iam.git modules/iam
else
    echo "✅ IAM module already exists"
fi

# Download EKS Auth module
echo "📦 Downloading EKS Auth module..."
if [ ! -d "modules/eks-auth" ]; then
    git clone --depth 1 --branch v1.0.0 https://github.com/aidanmelen/terraform-aws-eks-auth.git modules/eks-auth
else
    echo "✅ EKS Auth module already exists"
fi

echo ""
echo "✅ All modules downloaded successfully!"
echo ""
echo "🚀 Now run: terraform init"
