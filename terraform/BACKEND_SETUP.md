# Terraform Remote State Backend Setup

This document provides instructions for setting up the Terraform remote state backend using S3 and DynamoDB.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed

## Setup Instructions

### 1. Create the S3 Bucket

```bash
aws s3api create-bucket \
    --bucket your-terraform-state-bucket \
    --region us-east-1
```

### 2. Create the DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1
```

### 3. Update the backend.tf File

Replace the placeholder values in `backend.tf` with your actual bucket name and table name:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Replace with your bucket name
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"        # Replace with your table name
  }
}
```

### 4. Initialize Terraform with the New Backend

```bash
cd terraform
terraform init
```

This will prompt you to confirm that you want to migrate your local state to the new backend.

## Benefits of Using Remote State

- Team collaboration: Multiple team members can work on the same infrastructure
- State locking: Prevents concurrent modifications
- Encryption: State file is encrypted at rest
- Versioning: S3 provides versioning for state files
- Backup: Automatic backup of state files

## Security Considerations

- Enable S3 bucket encryption
- Enable S3 bucket versioning
- Restrict access to the S3 bucket and DynamoDB table using IAM policies
- Enable S3 bucket access logging
- Use separate buckets for different environments (dev, staging, prod)
