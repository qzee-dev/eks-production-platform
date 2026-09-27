# Module: EKS

This module creates an Amazon EKS cluster with encryption, logging, and security controls.

## Usage

```hcl
module "eks" {
  source = "../../modules/eks"

  project_name                   = "myapp"
  environment                    = "production"
  eks_version                    = "1.31"
  cluster_name                   = "myapp-production-eks"
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  cluster_endpoint_public_access = false
  cluster_endpoint_private_access = true
  public_access_cidrs            = []
  tags                          = local.common_tags
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| project_name | string | Yes | - | Project name for resource naming |
| environment | string | Yes | - | Environment name |
| eks_version | string | Yes | - | Kubernetes version for the cluster |
| cluster_name | string | Yes | - | Name of the EKS cluster |
| vpc_id | string | Yes | - | VPC ID where cluster will be created |
| private_subnet_ids | list(string) | Yes | - | Private subnet IDs for the cluster |
| cluster_endpoint_public_access | bool | No | false | Enable public access to API endpoint |
| cluster_endpoint_private_access | bool | No | true | Enable private access to API endpoint |
| public_access_cidrs | list(string) | No | [] | CIDR blocks for public endpoint access |
| tags | map(string) | No | {} | Additional tags for resources |
| kms_key_arn | string | No | null | KMS key ARN for EKS secrets encryption |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| cluster_name | string | EKS cluster name |
| cluster_endpoint | string | EKS cluster endpoint URL |
| cluster_certificate_authority_data | string | Cluster CA certificate (sensitive) |
| cluster_security_group_id | string | Security group ID for the cluster |
| cluster_role_arn | string | IAM role ARN for the cluster |
| kms_key_arn | string | KMS key ARN for secrets encryption |
