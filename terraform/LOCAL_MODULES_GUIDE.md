# Local Modules Setup Guide

## 🔴 Root Cause

The Terraform Registry is blocking access from your geographic location (detected via `x-amzn-waf-reason: geo` in HTTP response). This is a common issue in certain regions where the Terraform Registry restricts access.

## ✅ Solution

We've updated the Terraform configuration to use local modules instead of the Terraform Registry. This approach:

1. Bypasses the geographic restriction
2. Provides faster initialization (no downloads needed)
3. Gives you full control over module versions
4. Works offline after initial download

## 🛠 Setup Steps

### Step 1: Download Modules

Run the download script to fetch all required modules from GitHub:

```bash
cd /home/ghassan/End-to-End-DevOps-AWS-Go-MongoDB/terraform

# Make the script executable
chmod +x download_modules.sh

# Run the download script
./download_modules.sh
```

This script will download the following modules:
- VPC module (v5.7.2)
- EKS module (v20.0.0)
- IAM module (v6.2.3)
- EKS Auth module (v1.0.0)

### Step 2: Initialize Terraform

After downloading the modules, initialize Terraform:

```bash
# Clean Terraform cache (if needed)
rm -rf .terraform .terraform.lock.hcl

# Initialize Terraform
terraform init
```

## 📋 Module Configuration

All modules are now configured to use local sources:

| Module | Version | Local Source |
|--------|---------|--------------|
| vpc | 5.7.2 | ../vpc |
| eks | 20.0.0 | ../eks |
| ebs_csi_irsa_role | 6.2.3 | ../../iam/modules/iam-role-for-service-accounts-iam |
| iam_assumable_role_admin | 5.60.0 | ../../iam/modules/iam-assumable-role-with-oidc |
| eks_auth | 1.0.0 | ../eks-auth |

## 🔍 Verification

After initialization, verify that all modules are loaded correctly:

```bash
# Check loaded modules
terraform providers

# Validate configuration
terraform validate

# View execution plan
terraform plan
```

## 🚀 Next Steps

Once Terraform initializes successfully:

1. Review the execution plan:
   ```bash
   terraform plan
   ```

2. Apply the configuration:
   ```bash
   terraform apply
   ```

## 📝 Module Updates

To update modules to newer versions:

1. Edit the `download_modules.sh` script to change version tags
2. Remove old modules:
   ```bash
   rm -rf modules/*
   ```

3. Re-run the download script:
   ```bash
   ./download_modules.sh
   ```

4. Reinitialize Terraform:
   ```bash
   terraform init -upgrade
   ```

## 🎯 Benefits of Local Modules

1. **No Geographic Restrictions**: Works regardless of your location
2. **Faster Initialization**: No download time after initial setup
3. **Version Control**: You can commit modules to your repository
4. **Offline Capability**: Works without internet after initial download
5. **Custom Modifications**: You can customize modules if needed

## ⚠️ Important Notes

1. **Module Storage**: The `modules/` directory contains all Terraform modules
2. **Backup**: Original configuration files are backed up as `.backup` files
3. **Git Ignore**: Consider adding `.terraform/` to `.gitignore`
4. **State Management**: Ensure proper backend configuration for state management

## 🔄 Reverting to Registry

If you want to revert to using the Terraform Registry (when accessible):

1. Restore backup files:
   ```bash
   cp vpc.tf.backup vpc.tf
   cp eks.tf.backup eks.tf
   ```

2. Remove local modules:
   ```bash
   rm -rf modules/
   ```

3. Reinitialize Terraform:
   ```bash
   terraform init -upgrade
   ```

## 📚 Additional Resources

- [Terraform Module Sources](https://www.terraform.io/docs/language/modules/sources.html)
- [Terraform Registry](https://registry.terraform.io/)
- [AWS EKS Module](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)

## 🆘 Troubleshooting

### Module Not Found Error

If you get a "module not found" error:

1. Verify modules are downloaded:
   ```bash
   ls -la modules/
   ```

2. Check module paths in configuration files

3. Re-run download script:
   ```bash
   ./download_modules.sh
   ```

### Git Clone Failures

If git clone fails during download:

1. Configure Git for large files:
   ```bash
   git config --global http.postBuffer 524288000
   ```

2. Try downloading modules manually:
   ```bash
   cd modules
   git clone --depth 1 --branch v5.7.2 https://github.com/terraform-aws-modules/terraform-aws-vpc.git vpc
   ```

3. Use a VPN or proxy if GitHub is blocked

### Terraform Init Failures

If terraform init fails:

1. Clean Terraform cache:
   ```bash
   rm -rf .terraform .terraform.lock.hcl
   ```

2. Check module paths in configuration files

3. Verify all required modules are present in `modules/` directory

## ✅ Summary

Using local modules is a reliable solution when the Terraform Registry is not accessible. This approach provides:

- No geographic restrictions
- Faster initialization
- Better control over module versions
- Offline capability

Follow the setup steps above to get your Terraform infrastructure up and running!
