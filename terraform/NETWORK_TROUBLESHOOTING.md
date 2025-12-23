# Terraform Module Download Network Issues - Troubleshooting Guide

## 🔴 Root Cause

You're experiencing network connectivity issues when Terraform attempts to download modules from GitHub. The errors indicate:

```
error: RPC failed; curl 56 GnuTLS recv error (-54): Error in the pull function.
error: fetch-pack: unexpected disconnect while reading sideband packet
fatal: early EOF
```

These errors occur because:
1. Git is trying to clone large repositories over an unstable network connection
2. The connection is being interrupted during data transfer
3. GnuTLS (the SSL library used by Git) is encountering network errors

## 📌 Contributing Factors

1. **Unstable Network Connection**: Intermittent connectivity issues
2. **Large Repository Size**: Terraform modules can be quite large
3. **Git Configuration**: Default Git settings may not be optimized for your network
4. **Firewall/Proxy**: Corporate or local firewall restrictions
5. **DNS Issues**: Problems resolving GitHub's domain

## ✅ Recommended Solutions

### Solution 1: Increase Git Buffer Size (Recommended)

This is the most effective fix for large repository downloads:

```bash
# Increase Git's HTTP buffer size to handle large files
git config --global http.postBuffer 524288000

# Set longer timeout for Git operations
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# Increase Git buffer size for all protocols
git config --global core.compression 0
```

### Solution 2: Use SSH Instead of HTTPS

If you have SSH access to GitHub, switch to SSH:

```bash
# Test SSH connectivity to GitHub
ssh -T git@github.com

# If successful, configure Git to prefer SSH
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### Solution 3: Configure Git to Retry Failed Operations

```bash
# Configure Git to retry failed transfers
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 300
```

### Solution 4: Use Terraform Registry (Already Implemented)

Your configuration already uses Terraform Registry sources, which is more reliable than Git sources. However, Terraform still uses Git internally for some operations.

## 🛠 Step-by-Step Fix

### Step 1: Configure Git Settings

```bash
# Increase Git HTTP buffer size to 500MB
git config --global http.postBuffer 524288000

# Disable Git compression to speed up transfers
git config --global core.compression 0

# Set longer timeouts
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

### Step 2: Clean Terraform Cache

```bash
cd /home/ghassan/End-to-End-DevOps-AWS-Go-MongoDB/terraform

# Remove existing Terraform cache
rm -rf .terraform
rm -rf .terraform.lock.hcl
```

### Step 3: Test Network Connectivity

```bash
# Test DNS resolution for GitHub
nslookup github.com

# Test HTTP connectivity to GitHub
curl -I https://github.com

# Test Git clone with a small repository
git clone --depth 1 https://github.com/hashicorp/terraform-provider-aws /tmp/test-clone
rm -rf /tmp/test-clone
```

### Step 4: Retry Terraform Init

```bash
# Initialize Terraform with increased timeout
TF_REGISTRY_CLIENT_TIMEOUT=300 terraform init -upgrade
```

### Step 5: If Still Failing, Try Manual Module Download

```bash
# Create temporary directory for manual download
mkdir -p /tmp/terraform-modules

# Clone modules manually with increased buffer
cd /tmp/terraform-modules
git clone --depth 1 https://github.com/terraform-aws-modules/terraform-aws-eks.git
git clone --depth 1 https://github.com/terraform-aws-modules/terraform-aws-vpc.git

# Copy to Terraform module cache (if needed)
```

## 🔍 Verification Steps

### Test Git Configuration

```bash
# Verify Git settings
git config --global --list | grep -E "(http|core)"
```

Expected output should include:
```
http.postbuffer=524288000
core.compression=0
http.lowspeedlimit=0
http.lowspeedtime=999999
```

### Test Terraform Initialization

```bash
cd /home/ghassan/End-to-End-DevOps-AWS-Go-MongoDB/terraform

# Initialize with verbose output to see detailed progress
TF_LOG=DEBUG terraform init -upgrade 2>&1 | tee terraform-init.log
```

### Verify Module Download

```bash
# Check if modules were downloaded successfully
ls -la .terraform/modules/

# Verify module versions
terraform providers
```

## Additional Solutions

### If Using Corporate Network

If you're behind a corporate firewall or proxy:

```bash
# Configure Git to use proxy (if needed)
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy https://proxy.company.com:8080

# Or configure environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=https://proxy.company.com:8080
```

### If Using WSL (Windows Subsystem for Linux)

If you're running on WSL, there might be network issues:

```bash
# Check WSL network configuration
cat /etc/resolv.conf

# Try using Windows DNS
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf

# Restart WSL networking
sudo service networking restart
```

## Prevention Strategies

1. **Use Terraform Registry**: Already implemented - prefer registry sources over Git sources
2. **Pin Module Versions**: Already done - prevents unexpected changes
3. **Commit .terraform.lock.hcl**: Locks provider and module versions
4. **Use CI/CD with Stable Network**: Run Terraform in a reliable network environment
5. **Implement Retry Logic**: Use CI/CD pipelines with automatic retry on failure

## Quick Fix Command Sequence

```bash
# Configure Git for large downloads
git config --global http.postBuffer 524288000
git config --global core.compression 0
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

# Clean Terraform cache
cd /home/ghassan/End-to-End-DevOps-AWS-Go-MongoDB/terraform
rm -rf .terraform .terraform.lock.hcl

# Initialize with increased timeout
TF_REGISTRY_CLIENT_TIMEOUT=300 terraform init -upgrade
```

## If All Else Fails

If you continue to experience issues after trying all solutions:

1. **Use a Different Network**: Try from a different network connection
2. **Use VPN**: If corporate network is restricting access
3. **Contact Network Administrator**: Check if GitHub is being blocked
4. **Use Terraform Cloud**: Consider using Terraform Cloud for remote execution
5. **Manual Module Download**: Download modules manually and configure local sources

## Monitoring Progress

While terraform init is running, you can monitor progress:

```bash
# Watch Terraform logs in another terminal
tail -f terraform-init.log

# Monitor network activity
sudo netstat -i
```

## Summary

The primary issue is network instability when downloading large Terraform modules from GitHub. The recommended approach is to:

1. Increase Git's HTTP buffer size
2. Disable Git compression
3. Increase timeout settings
4. Clean Terraform cache
5. Retry terraform init with increased timeout

These changes should resolve the download failures and allow Terraform to successfully initialize.
