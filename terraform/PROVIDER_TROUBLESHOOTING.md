# Terraform Provider Troubleshooting Guide

## 🔴 Root Cause

The provider version conflict occurs because multiple Terraform modules in your infrastructure have declared incompatible AWS provider version constraints. When Terraform initializes, it must find a single provider version that satisfies ALL constraints from:
- Root module (versions.tf): `~> 5.20.0` (now fixed to `~> 6.0.0`)
- EKS module (v20.0.0): Requires AWS provider `>= 5.30.0`
- VPC module (v5.7.2): Requires AWS provider `>= 5.34.0`
- Other modules: Various older constraints

These constraints cannot be satisfied together because they require mutually exclusive version ranges.

## 📌 Contributing Factors

1. **Module Version Mismatch**: Using EKS module v20.0.0 with VPC module v5.7.2 creates incompatible provider requirements

2. **Outdated Root Module Constraint**: Root module's provider version was too restrictive for child modules being used

3. **Network Timeout Issues**: Provider download failures suggest:
   - Poor network connectivity to Terraform Registry
   - Possible firewall/proxy restrictions
   - DNS resolution issues
   - Registry availability problems

## ✅ Recommended Fix

Updated the AWS provider version constraint in the root module to `~> 6.0.0` to satisfy all child module requirements. This is the highest common denominator that will work with all modules.

## 🛠 Exact Code Changes

### 1. Updated versions.tf

```hcl
terraform {
  required_version = ">= 1.0, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
  }
}
```

## 🔍 Verification Steps

### 1. Clean and Reinitialize Terraform

```bash
cd terraform

# Remove existing Terraform cache and state
rm -rf .terraform
rm -rf .terraform.lock.hcl

# Initialize with upgraded providers
terraform init -upgrade
```

### 2. Verify Provider Installation

```bash
# Check which providers will be used
terraform providers

# Verify provider versions
terraform version
```

### 3. Validate Configuration

```bash
# Validate Terraform configuration
terraform validate

# Check for any remaining issues
terraform plan
```

## Network Troubleshooting Commands

### Test Terraform Registry Connectivity

```bash
# Test DNS resolution for Terraform Registry
nslookup registry.terraform.io

# Test HTTP connectivity to Terraform Registry
curl -I https://registry.terraform.io

# Test provider download endpoint
curl -I https://releases.hashicorp.com
```

### Check Firewall/Proxy Settings

```bash
# Check if HTTP proxy is set
echo $HTTP_PROXY
echo $HTTPS_PROXY

# Test connectivity through proxy if configured
curl -I https://registry.terraform.io --proxy $HTTP_PROXY
```

### Alternative: Use Provider Mirror (if needed)

If you're experiencing persistent network issues, you can configure a provider mirror:

1. Create a `.terraformrc` or `terraform.rc` file in your home directory:

```hcl
provider_installation {
  network_mirror {
    url = "https://your-mirror.example.com/terraform-providers"
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

2. Or configure environment variables:

```bash
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
export TF_REGISTRY_CLIENT_TIMEOUT=120s
```

## Prevention Strategies

### 1. Provider Version Pinning Best Practices

- Always use `~>` for provider versions in root module
- Pin to specific major.minor versions (e.g., `~> 6.0.0`)
- Commit `.terraform.lock.hcl` to version control
- Review module provider requirements before upgrading

### 2. Module Selection Guidelines

- Choose modules with compatible provider requirements
- Check module documentation for provider version constraints
- Test module compatibility in non-production environment first
- Keep modules updated to latest stable versions

### 3. CI/CD Integration

```yaml
# Example GitHub Actions workflow
- name: Terraform Init
  run: |
    terraform init -upgrade
    terraform providers
    terraform validate
```

## Common Issues and Solutions

### Issue 1: Provider Download Timeout

**Solution**: Increase timeout or use mirror
```bash
export TF_REGISTRY_CLIENT_TIMEOUT=180s
terraform init
```

### Issue 2: Module Provider Conflicts

**Solution**: Create a `versions.tf` in root module with compatible versions
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
  }
}
```

### Issue 3: Outdated Lock File

**Solution**: Regenerate lock file
```bash
rm .terraform.lock.hcl
terraform init -upgrade
```

## Additional Resources

- [Terraform Provider Versioning](https://www.terraform.io/docs/language/providers/requirements.html)
- [Terraform Module Development](https://www.terraform.io/docs/registry/modules/publish.html)
- [Terraform Provider Network Mirrors](https://www.terraform.io/docs/cli/config/config-file.html#provider-installation)
