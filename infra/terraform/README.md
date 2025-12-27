# Terraform Infrastructure Documentation

This directory contains the Terraform configuration for provisioning the AWS infrastructure required for the Go Survey application.

## Table of Contents

- [Terraform Structure](#terraform-structure)
- [Modules Explanation](#modules-explanation)
- [State & Backend Design](#state--backend-design)
- [Apply / Destroy Flow](#apply--destroy-flow)

---

## Terraform Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── eks/             # EKS cluster module
│   ├── eks-auth/        # EKS authentication module
│   ├── iam/             # IAM roles and policies
│   ├── kms/             # KMS encryption keys
│   └── vpc/             # VPC networking
├── backend.tf           # Terraform state backend configuration
├── provider.tf          # Provider configurations
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── main.tf              # Main configuration
├── vpc.tf               # VPC configuration
├── eks.tf               # EKS cluster configuration
├── ecr.tf               # ECR repository configuration
├── k8s-nginx-ingress.tf # Ingress controller configuration
├── monitoring.tf        # Monitoring stack configuration
├── versions.tf          # Terraform and provider version constraints
└── terraform.tfvars.example # Example variables file
```

---

## Modules Explanation

### EKS Module

Provisions an Amazon EKS cluster with:
- Managed node groups
- IAM roles for cluster and nodes
- VPC integration
- Security groups

### EKS Auth Module

Configures AWS IAM authentication for EKS:
- Maps IAM users to Kubernetes RBAC
- Defines admin and developer roles
- Manages aws-auth ConfigMap

### IAM Module

Creates and manages IAM resources:
- Roles for EKS cluster and nodes
- Policies for ECR access
- Roles for monitoring components

### KMS Module

Manages encryption keys:
- EBS volume encryption
- EKS secrets encryption
- Key policies for access control

### VPC Module

Sets up networking infrastructure:
- Public and private subnets
- Internet and NAT gateways
- Route tables
- Security groups

---

## State & Backend Design

### Remote State Storage

Terraform state is stored remotely in an S3 bucket with the following features:
- Encryption at rest
- Versioning
- State locking with DynamoDB

### Backend Configuration

The backend is configured in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "eks-go-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "your-terraform-lock-table"
  }
}
```

### Setting Up the Backend

1. Create an S3 bucket for state storage:
   ```bash
   aws s3api create-bucket \
     --bucket your-terraform-state-bucket \
     --region us-east-1
   ```

2. Enable versioning:
   ```bash
   aws s3api put-bucket-versioning \
     --bucket your-terraform-state-bucket \
     --versioning-configuration Status=Enabled
   ```

3. Create a DynamoDB table for state locking:
   ```bash
   aws dynamodb create-table \
     --table-name your-terraform-lock-table \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region us-east-1
   ```

4. Update `backend.tf` with your bucket and table names

---

## Apply / Destroy Flow

### Initial Setup

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Review the plan**:
   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply tfplan
   ```

### Workflow Changes

1. **Make changes to Terraform files**

2. **Review the plan**:
   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply the changes**:
   ```bash
   terraform apply tfplan
   ```

### Destroying Infrastructure

1. **Review what will be destroyed**:
   ```bash
   terraform plan -destroy
   ```

2. **Destroy the infrastructure**:
   ```bash
   terraform destroy -auto-approve
   ```

### Using the Build Script

The repository includes a `build.sh` script that automates the entire workflow:

```bash
# From the repository root
./build.sh
```

This script will:
1. Initialize and apply Terraform configuration
2. Update kubeconfig
3. Build and push the Docker image
4. Deploy the application to Kubernetes

### Using the Destroy Script

The `destroy.sh` script automates cleanup:

```bash
# From the repository root
./destroy.sh
```

This script will:
1. Delete Docker images from ECR
2. Remove Kubernetes resources
3. Destroy Terraform-managed infrastructure

---

## Variables

### Required Variables

These variables must be set before applying the configuration:

| Variable | Description | Default |
|----------|-------------|---------|
| `name_prefix` | Prefix for resource names | `cluster-1` |
| `region` | AWS region | `us-east-1` |
| `environment` | Environment name | `test` |
| `domain_name` | Domain for monitoring stack | - |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `main_network_block` | VPC CIDR block | `10.0.0.0/16` |
| `asg_sys_instance_types` | System node instance types | `["t3a.medium"]` |
| `asg_dev_instance_types` | Dev node instance types | `["t3a.medium"]` |
| `autoscaling_minimum_size_by_az` | Min nodes per AZ | `1` |
| `autoscaling_maximum_size_by_az` | Max nodes per AZ | `2` |
| `autoscaling_average_cpu` | CPU scaling threshold | `60` |

---

## Outputs

The Terraform configuration outputs the following values:

| Output | Description |
|--------|-------------|
| `cluster_endpoint` | EKS cluster API endpoint |
| `cluster_security_group_id` | Security group ID for the cluster |
| `cluster_name` | Name of the EKS cluster |
| `region` | AWS region |
| `vpc_id` | VPC ID |

---

## Best Practices

1. **Always review the plan before applying**: Use `terraform plan` to understand what changes will be made

2. **Use version control**: Commit all Terraform files to version control

3. **Store state remotely**: Use S3 with DynamoDB for state locking

4. **Use modules**: Organize code into reusable modules

5. **Document variables**: Provide clear descriptions for all variables

6. **Tag resources**: Use consistent tagging for cost management and organization

7. **Limit permissions**: Use IAM roles with least-privilege access

8. **Enable encryption**: Encrypt all sensitive data at rest

---

## Troubleshooting

### State Lock Issues

If you encounter state lock issues:

```bash
# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### Provider Issues

If you encounter provider issues:

```bash
# Reinitialize Terraform
terraform init -upgrade
```

### Module Issues

If you encounter module issues:

```bash
# Clean and reinitialize
rm -rf .terraform
terraform init
```

---

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)