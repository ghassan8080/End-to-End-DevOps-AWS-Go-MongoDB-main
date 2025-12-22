#!/bin/bash
# Script to initialize Terraform with proper module and provider versions

echo "Removing .terraform directory..."
rm -rf .terraform

echo "Initializing Terraform with upgrade flag..."
terraform init -upgrade

echo "Checking Terraform version..."
terraform version

echo "Checking Terraform providers..."
terraform providers
