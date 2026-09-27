# Module: VPC

This module creates a production-ready VPC with public and private subnets across multiple availability zones, NAT gateways, and route tables.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name        = "myapp"
  environment         = "production"
  region              = "us-east-1"
  vpc_cidr            = "10.30.0.0/16"
  public_subnet_cidrs = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
  private_subnet_cidrs = ["10.30.11.0/24", "10.30.12.0/24", "10.30.13.0/24"]
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  tags                = local.common_tags
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| project_name | string | Yes | - | Project name for resource naming |
| environment | string | Yes | - | Environment name (dev/staging/production) |
| region | string | Yes | - | AWS region |
| vpc_cidr | string | Yes | - | CIDR block for the VPC |
| public_subnet_cidrs | list(string) | Yes | - | List of public subnet CIDR blocks |
| private_subnet_cidrs | list(string) | Yes | - | List of private subnet CIDR blocks |
| availability_zones | list(string) | Yes | - | Availability zones for subnets |
| tags | map(string) | No | {} | Additional tags for resources |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| vpc_id | string | VPC ID |
| public_subnet_ids | list(string) | Public subnet IDs |
| private_subnet_ids | list(string) | Private subnet IDs |
| public_route_table_id | string | Public route table ID |
| nat_gateway_ids | list(string) | NAT gateway IDs |
| vpc_cidr | string | VPC CIDR block |
