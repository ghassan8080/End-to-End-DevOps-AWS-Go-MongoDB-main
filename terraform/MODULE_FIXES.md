# Terraform Module Source Fixes

## 🔴 Root Cause

Terraform was failing to download modules because some modules were using sub-module paths (e.g., `terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc`), which forces Terraform to use Git to clone the entire repository and then access the sub-module. This approach:

1. Requires Git to be installed and configured
2. Downloads the entire repository (much larger than needed)
3. Is more prone to network failures
4. Slower than using the Terraform Registry

## 📌 Affected Modules

1. **ebs_csi_irsa_role**: Was using `terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts`
2. **iam_assumable_role_admin**: Was using `terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc`

## ✅ Fixes Applied

### 1. EBS CSI IRSA Role Module

**Before:**
```hcl
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name                  = "${local.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true
  # ...
}
```

**After:**
```hcl
module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws"
  version = "6.2.3"

  name                  = "${local.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true
  # ...
}
```

### 2. IAM Assumable Role Admin Module

**Before:**
```hcl
module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 5.0"

  create_role                   = true
  role_name                     = "${local.cluster_name}-cluster-autoscaler"
  # ...
}
```

**After:**
```hcl
module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws"
  version                       = "5.60.0"

  create_role                   = true
  role_name                     = "${local.cluster_name}-cluster-autoscaler"
  # ...
}
```

## 🛠 Why This Works

When using the Terraform Registry without sub-module paths:

1. **Faster Downloads**: Terraform downloads only the specific module version needed
2. **No Git Required**: Uses HTTP/HTTPS to download from the registry
3. **More Reliable**: Less prone to network failures
4. **Version Pinned**: Exact version is specified and locked
5. **Better Caching**: Terraform can cache registry downloads more effectively

## 🔍 Verification Steps

After applying these fixes, run:

```bash
# Clean Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Initialize Terraform
terraform init -upgrade

# Verify modules downloaded
ls -la .terraform/modules/

# Validate configuration
terraform validate
```

## 📋 Module Versions

All modules now use Terraform Registry sources with pinned versions:

| Module | Version | Source |
|---------|----------|---------|
| vpc | 5.7.2 | terraform-aws-modules/vpc/aws |
| eks | 20.0.0 | terraform-aws-modules/eks/aws |
| ebs_csi_irsa_role | 6.2.3 | terraform-aws-modules/iam/aws |
| iam_assumable_role_admin | 5.60.0 | terraform-aws-modules/iam/aws |
| eks_auth | 1.0.0 | aidanmelen/eks-auth/aws |

## 🎯 Best Practices

1. **Always use Terraform Registry** for public modules when possible
2. **Pin module versions** to specific versions (not just `~>`)
3. **Avoid sub-module paths** (`//modules/...`) in source URLs
4. **Commit .terraform.lock.hcl** to version control
5. **Use `terraform init -upgrade`** to update provider and module versions

## 🚀 Next Steps

1. Run `terraform init -upgrade` to download all modules
2. Run `terraform validate` to check configuration
3. Run `terraform plan` to see planned changes
4. Run `terraform apply` to create/update infrastructure

All modules should now download successfully without requiring Git or encountering network issues!
