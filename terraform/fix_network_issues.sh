#!/bin/bash
# Terraform Network Issues Quick Fix Script

echo "🔧 Configuring Git for large repository downloads..."

# Increase Git HTTP buffer size to 500MB
git config --global http.postBuffer 524288000

# Disable Git compression to speed up transfers
git config --global core.compression 0

# Set longer timeouts
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

echo "✅ Git configuration updated successfully!"
echo ""
echo "Current Git settings:"
git config --global --list | grep -E "(http|core)"
echo ""
echo "🧹 Cleaning Terraform cache..."
cd /home/ghassan/End-to-End-DevOps-AWS-Go-MongoDB/terraform
rm -rf .terraform .terraform.lock.hcl

echo "✅ Terraform cache cleaned!"
echo ""
echo "🚀 Initializing Terraform with increased timeout..."
TF_REGISTRY_CLIENT_TIMEOUT=300 terraform init -upgrade
