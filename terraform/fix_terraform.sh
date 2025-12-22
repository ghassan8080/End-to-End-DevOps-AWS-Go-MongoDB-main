#!/bin/bash
# Script to fix Terraform module and provider issues

echo "Cleaning up Terraform cache..."
rm -rf .terraform
rm -f .terraform.lock.hcl

echo "Initializing Terraform..."
terraform init

echo "Checking Terraform plan..."
terraform plan
