# Terraform EKS Production Platform - Operations Guide

## Quick Start

### 1. Bootstrap Infrastructure (One-Time)

```bash
bash scripts/bootstrap-state.sh
```

This creates:
- S3 buckets for state storage (dev, staging, production)
- DynamoDB lock tables for state locking
- Encryption and versioning on all buckets

### 2. Initialize Environment

**Development:**
```bash
bash scripts/init-env.sh dev
```

**Staging:**
```bash
bash scripts/init-env.sh staging
```

**Production:**
```bash
bash scripts/init-env.sh production
```

### 3. Plan Deployment

```bash
bash scripts/plan-env.sh [dev|staging|production]
```

Review the plan output carefully before applying.

### 4. Apply Deployment

```bash
bash scripts/apply-env.sh [dev|staging|production]
```

For production, you'll be prompted to confirm before proceeding.

## State Management

### View State Configuration

```bash
bash scripts/ops.sh state-status
```

### Backup State Files

```bash
bash scripts/backup-state.sh
```

Backups are saved to `state-backups/[timestamp]/`

### Restore State File

```bash
aws s3 cp state-backups/[timestamp]/terraform-[env].tfstate s3://myapp-terraform-state-[env]/eks/[env]/terraform.tfstate
```

## Directory Structure

```
terraform/
├── modules/
│   ├── vpc/              # VPC, subnets, NAT, route tables
│   ├── eks/              # EKS cluster, IAM, KMS, security groups
│   ├── node-group/       # Managed node groups, IAM roles
│   └── addons/           # EKS add-ons (VPC CNI, CoreDNS, EBS CSI, kube-proxy)
│
└── environments/
    ├── dev/              # Development environment
    │   ├── backend.tf    # S3: myapp-terraform-state-dev
    │   ├── providers.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── outputs.tf
    │
    ├── staging/          # Staging environment
    │   ├── backend.tf    # S3: myapp-terraform-state-staging
    │   ├── providers.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── terraform.tfvars
    │   └── outputs.tf
    │
    └── production/       # Production environment
        ├── backend.tf    # S3: myapp-terraform-state-prod
        ├── providers.tf
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        └── outputs.tf
```

## Environment Configuration

### Development
- **VPC CIDR**: 10.10.0.0/16
- **Kubernetes Version**: 1.30
- **Node Type**: t3.medium
- **Node Count**: 2 (min: 1, max: 3)
- **API Access**: Public + Private
- **State Bucket**: myapp-terraform-state-dev
- **Lock Table**: myapp-terraform-state-dev-lock

### Staging
- **VPC CIDR**: 10.20.0.0/16
- **Kubernetes Version**: 1.30
- **Node Type**: t3.large
- **Node Count**: 3 (min: 2, max: 5)
- **API Access**: Private only
- **State Bucket**: myapp-terraform-state-staging
- **Lock Table**: myapp-terraform-state-staging-lock

### Production
- **VPC CIDR**: 10.30.0.0/16
- **Kubernetes Version**: 1.31
- **Node Type**: m5.large
- **Node Count**: 3 (min: 3, max: 10)
- **AZs**: 3 (us-east-1a, us-east-1b, us-east-1c)
- **API Access**: Private only
- **State Bucket**: myapp-terraform-state-prod
- **Lock Table**: myapp-terraform-state-prod-lock

## Validation

### Validate All Environments

```bash
bash scripts/validate-all.sh
```

### Format Code

```bash
terraform fmt -recursive terraform/
```

## Common Tasks

### Scale a Cluster

Edit `terraform/environments/[env]/terraform.tfvars`:

```hcl
desired_size = 5
min_size     = 3
max_size     = 10
```

Then:
```bash
bash scripts/plan-env.sh [env]
bash scripts/apply-env.sh [env]
```

### Upgrade Kubernetes Version

Edit `terraform/environments/[env]/terraform.tfvars`:

```hcl
eks_version = "1.31"
```

Then:
```bash
bash scripts/plan-env.sh [env]
bash scripts/apply-env.sh [env]
```

### Change Instance Type

Edit `terraform/environments/[env]/terraform.tfvars`:

```hcl
node_instance_types = ["m5.xlarge"]
```

Then:
```bash
bash scripts/plan-env.sh [env]
bash scripts/apply-env.sh [env]
```

## State Isolation Benefits

✅ **Complete Isolation**: Each environment has its own state file in its own S3 bucket
✅ **Independent Deployments**: dev and staging deployments do not block each other
✅ **Safe Testing**: New changes can be tested in dev without affecting production
✅ **Easy Recovery**: Each environment can be backed up and restored independently
✅ **Per-Environment IAM**: Access control can be configured per environment
✅ **Concurrent Operations**: Multiple teams can work on different environments simultaneously

## Troubleshooting

### State Lock Timeout

```bash
aws dynamodb scan --table-name myapp-terraform-state-[env]-lock --region us-east-1
```

### Force Unlock (Use with Caution)

```bash
cd terraform/environments/[env]
terraform force-unlock [LOCK_ID]
```

### Verify State Isolation

```bash
for ENV in dev staging production; do
  echo "$ENV state:"
  aws s3 ls s3://myapp-terraform-state-${ENV}/
done
```

### Check Cluster Status

```bash
cd terraform/environments/[env]
terraform output cluster_name
terraform output cluster_endpoint

# Get kubeconfig
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region us-east-1

# Verify nodes
kubectl get nodes
```

## Security Checklist

- [ ] S3 state buckets have versioning enabled
- [ ] S3 state buckets have encryption enabled
- [ ] Public access is blocked on state buckets
- [ ] DynamoDB lock tables exist for each environment
- [ ] IAM roles have least-privilege permissions
- [ ] Production cluster API is private-only
- [ ] KMS encryption is enabled for EKS secrets
- [ ] CloudWatch logging is enabled
- [ ] State files are NOT committed to Git
- [ ] No AWS credentials are hardcoded

## Production Deployment Checklist

- [ ] All environments validated: `bash scripts/validate-all.sh`
- [ ] Dev environment tested and stable
- [ ] Staging environment mirrors production configuration
- [ ] Production plan reviewed and approved
- [ ] Backup taken before production deployment
- [ ] Production deployment executed: `bash scripts/apply-env.sh production`
- [ ] Kubeconfig updated and cluster verified
- [ ] Nodes healthy and pods running
- [ ] Application deployments successful
- [ ] Monitoring and logging configured

## Support

For issues or questions:
1. Check TERRAFORM_STATE_ARCHITECTURE.md for detailed state management info
2. Review Terraform logs: `TF_LOG=DEBUG terraform plan`
3. Validate AWS credentials and IAM permissions
4. Check AWS CloudTrail for API errors

## References

- [Terraform AWS EKS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/s3)
