# Module: Node Group

This module creates managed EKS node groups with auto-scaling and IAM roles.

## Usage

```hcl
module "node_group" {
  source = "../../modules/node-group"

  project_name    = "myapp"
  environment     = "production"
  cluster_name    = module.eks.cluster_name
  cluster_version = "1.31"
  node_group_name = "general"
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = ["m5.large"]
  desired_size    = 3
  min_size        = 3
  max_size        = 10
  capacity_type   = "ON_DEMAND"
  labels = {
    role = "general"
  }
  tags = local.common_tags
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| project_name | string | Yes | - | Project name for resource naming |
| environment | string | Yes | - | Environment name |
| cluster_name | string | Yes | - | EKS cluster name |
| cluster_version | string | Yes | - | Kubernetes version |
| node_group_name | string | Yes | - | Name of the node group |
| subnet_ids | list(string) | Yes | - | Subnet IDs for node group |
| instance_types | list(string) | Yes | - | Instance types for nodes |
| desired_size | number | Yes | - | Desired number of nodes |
| min_size | number | Yes | - | Minimum number of nodes |
| max_size | number | Yes | - | Maximum number of nodes |
| capacity_type | string | No | ON_DEMAND | Capacity type (ON_DEMAND or SPOT) |
| labels | map(string) | No | {} | Kubernetes labels for nodes |
| tags | map(string) | No | {} | Additional tags for resources |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| node_group_name | string | Name of the managed node group |
| node_role_arn | string | IAM role ARN for nodes |
| node_role_id | string | IAM role ID for nodes |
