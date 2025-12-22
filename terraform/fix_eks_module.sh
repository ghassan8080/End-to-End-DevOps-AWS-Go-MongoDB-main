#!/bin/bash
# Script to fix the EKS module configuration

echo "Removing .terraform directory..."
rm -rf .terraform

echo "Updating EKS module to a compatible version..."
# Update the EKS module to version 19.13.0 which should be compatible with our configuration
sed -i 's/version = "15.5.0"/version = "19.13.0"/' eks.tf

echo "Initializing Terraform..."
terraform init

echo "Checking Terraform plan..."
terraform plan
