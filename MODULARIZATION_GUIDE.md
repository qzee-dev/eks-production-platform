# Multi-Environment Terraform Architecture

This repository implements a **fully modularized, multi-environment Terraform architecture** for Amazon EKS. Each environment (dev, staging, production) is completely independent with isolated state management, configuration, and infrastructure.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Modularized Infrastructure                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │   VPC Module     │  │   EKS Module     │  │  Add-ons     │ │
│  │                  │  │                  │  │  Module      │ │
│  │ • Subnets        │  │ • Cluster        │  │              │ │
│  │ • NAT Gateways   │  │ • IAM Roles      │  │ • VPC CNI    │ │
│  │ • Route Tables   │  │ • KMS Encryption │  │ • CoreDNS    │ │
│  │ • Security Groups│  │ • Logging        │  │ • EBS CSI    │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│           △                     △                     △         │
│           │                     │                     │         │
│           └─────────┬───────────┴─────────┬───────────┘         │
│                     │                     │                     │
│          ┌──────────▼──────────────────────▼──────────┐         │
│          │   Environment Root Module                 │         │
│          │   (main.tf, variables.tf, outputs.tf)     │         │
│          │                                           │         │
│          │  • Composes all modules                   │         │
│          │  • Passes environment-specific values     │         │
│          │  • Manages locals and tagging             │         │
│          └──────────────────────────────────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
terraform/
│
├── modules/                    # Reusable Terraform modules
│   ├── vpc/
│   │   ├── main.tf            # VPC, subnets, NAT, route tables
│   │   ├── variables.tf       # Module input variables
│   │   ├── outputs.tf         # Module outputs
│   │   └── README.md          # Module documentation
│   │
│   ├── eks/
│   │   ├── main.tf            # EKS cluster, IAM, KMS, security
│   │   ├── variables.tf       # Module input variables
│   │   ├── outputs.tf         # Module outputs
│   │   └── README.md          # Module documentation
│   │
│   ├── node-group/
│   │   ├── main.tf            # Managed node groups, scaling
│   │   ├── variables.tf       # Module input variables
│   │   ├── outputs.tf         # Module outputs
│   │   └── README.md          # Module documentation
│   │
│   └── addons/
│       ├── main.tf            # EKS add-ons installation
│       ├── variables.tf       # Module input variables
│       ├── outputs.tf         # Module outputs
│       └── README.md          # Module documentation
│
└── environments/              # Environment-specific configurations
    ├── dev/                   # Development environment
    │   ├── backend.tf         # S3 backend (dev state bucket)
    │   ├── providers.tf       # AWS provider configuration
    │   ├── versions.tf        # Terraform version constraints
    │   ├── main.tf            # Environment root (composes modules)
    │   ├── variables.tf       # Environment input variables
    │   ├── locals.tf          # Environment local values
    │   ├── terraform.tfvars   # Environment variable values
    │   └── outputs.tf         # Environment outputs
    │
    ├── staging/               # Staging environment
    │   ├── backend.tf         # S3 backend (staging state bucket)
    │   ├── providers.tf       # AWS provider configuration
    │   ├── versions.tf        # Terraform version constraints
    │   ├── main.tf            # Environment root (composes modules)
    │   ├── variables.tf       # Environment input variables
    │   ├── locals.tf          # Environment local values
    │   ├── terraform.tfvars   # Environment variable values
    │   └── outputs.tf         # Environment outputs
    │
    └── production/            # Production environment
        ├── backend.tf         # S3 backend (production state bucket)
        ├── providers.tf       # AWS provider configuration
        ├── versions.tf        # Terraform version constraints
        ├── main.tf            # Environment root (composes modules)
        ├── variables.tf       # Environment input variables
        ├── locals.tf          # Environment local values
        ├── terraform.tfvars   # Environment variable values
        └── outputs.tf         # Environment outputs
```

## How Modularization Works

### 1. Module Layer (terraform/modules/)

Each module is self-contained and reusable:

```hcl
# terraform/modules/vpc/main.tf
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(
    { Name = "${var.project_name}-${var.environment}-vpc" },
    var.tags
  )
}
```

Modules accept variables but don't hardcode environment-specific values:

```hcl
# terraform/modules/vpc/variables.tf
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "Environment name (dev/staging/production)"
}
```

### 2. Environment Layer (terraform/environments/)

Each environment composes modules with environment-specific values:

```hcl
# terraform/environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  tags                = local.common_tags
}
```

Environments provide values through tfvars:

```hcl
# terraform/environments/dev/terraform.tfvars
project_name        = "myapp"
environment         = "dev"
vpc_cidr            = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]
```

### 3. State Isolation

Each environment has its own backend configuration:

```hcl
# terraform/environments/dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-dev"
    key            = "eks/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "myapp-terraform-state-dev-lock"
  }
}
```

## Environment Configurations

### Development Environment

**Purpose**: Testing and experimentation

```hcl
# terraform/environments/dev/terraform.tfvars
project_name        = "myapp"
environment         = "dev"
region              = "us-east-1"
vpc_cidr            = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]
eks_version         = "1.30"
cluster_name        = "myapp-dev-eks"
cluster_endpoint_public_access = true
node_instance_types = ["t3.medium"]
desired_size        = 2
min_size            = 1
max_size            = 3
```

**State**: `s3://myapp-terraform-state-dev/eks/dev/terraform.tfstate`

### Staging Environment

**Purpose**: Pre-production validation

```hcl
# terraform/environments/staging/terraform.tfvars
project_name        = "myapp"
environment         = "staging"
region              = "us-east-1"
vpc_cidr            = "10.20.0.0/16"
public_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]
eks_version         = "1.30"
cluster_name        = "myapp-staging-eks"
cluster_endpoint_public_access = false
node_instance_types = ["t3.large"]
desired_size        = 3
min_size            = 2
max_size            = 5
```

**State**: `s3://myapp-terraform-state-staging/eks/staging/terraform.tfstate`

### Production Environment

**Purpose**: Live production workloads

```hcl
# terraform/environments/production/terraform.tfvars
project_name        = "myapp"
environment         = "production"
region              = "us-east-1"
vpc_cidr            = "10.30.0.0/16"
public_subnet_cidrs = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
private_subnet_cidrs = ["10.30.11.0/24", "10.30.12.0/24", "10.30.13.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
eks_version         = "1.31"
cluster_name        = "myapp-production-eks"
cluster_endpoint_public_access = false
node_instance_types = ["m5.large"]
desired_size        = 3
min_size            = 3
max_size            = 10
```

**State**: `s3://myapp-terraform-state-prod/eks/production/terraform.tfstate`

## Module Composition Pattern

Each environment follows the same composition pattern:

```hcl
# terraform/environments/[env]/main.tf

# Define common tags
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

# Compose VPC module
module "vpc" {
  source = "../../modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  tags                = local.common_tags
}

# Compose EKS module
module "eks" {
  source = "../../modules/eks"

  project_name                   = var.project_name
  environment                    = var.environment
  eks_version                    = var.eks_version
  cluster_name                   = var.cluster_name
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  public_access_cidrs            = var.public_access_cidrs
  tags                          = local.common_tags
}

# Compose Node Group module
module "node_group" {
  source = "../../modules/node-group"

  project_name    = var.project_name
  environment     = var.environment
  cluster_name    = module.eks.cluster_name
  cluster_version = var.eks_version
  node_group_name = "general"
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = var.node_instance_types
  desired_size    = var.desired_size
  min_size        = var.min_size
  max_size        = var.max_size
  capacity_type   = "ON_DEMAND"
  labels          = var.node_labels
  tags            = local.common_tags
}

# Compose Add-ons module
module "addons" {
  source = "../../modules/addons"

  cluster_name    = module.eks.cluster_name
  cluster_version = var.eks_version
  tags            = local.common_tags
}
```

## Deployment Flow

### 1. Initialize Environment

```bash
cd terraform/environments/dev
terraform init
```

This:
- Downloads modules from `../../modules/`
- Configures the S3 backend for state
- Initializes the DynamoDB lock table

### 2. Validate Configuration

```bash
terraform validate
```

Ensures:
- All variables are declared
- All module outputs are valid
- Terraform syntax is correct

### 3. Plan Deployment

```bash
terraform plan -var-file=terraform.tfvars -out=plan.dev
```

Generates:
- Execution plan showing what will be created
- Review before applying changes

### 4. Apply Changes

```bash
terraform apply plan.dev
```

Creates:
- VPC infrastructure
- EKS cluster
- Managed node groups
- Add-ons
- All IAM roles and security groups

## Advantages of This Architecture

### Modularity
- ✅ Each module has single responsibility
- ✅ Modules are reusable across environments
- ✅ No code duplication
- ✅ Easy to extend with new modules

### Isolation
- ✅ Each environment has independent state
- ✅ Changes in dev don't affect staging or production
- ✅ Each environment can be deployed/destroyed independently
- ✅ Concurrent deployments across environments

### Scalability
- ✅ Easy to add new environments (e.g., QA, preprod)
- ✅ Modules scale to handle different sizes
- ✅ Configuration is parametrized, not hardcoded

### Maintainability
- ✅ Single source of truth for each resource type
- ✅ Changes to modules propagate to all environments
- ✅ Clear separation of concerns
- ✅ Environment-specific overrides are explicit

### Security
- ✅ Each environment has separate IAM permissions
- ✅ Production is private by default
- ✅ KMS encryption for secrets
- ✅ CloudWatch logging enabled
- ✅ Least-privilege IAM policies

## Common Operations

### Scale a Cluster

Edit `terraform/environments/[env]/terraform.tfvars`:
```hcl
desired_size = 5
min_size     = 3
max_size     = 10
```

Then:
```bash
cd terraform/environments/[env]
terraform apply -var-file=terraform.tfvars
```

### Upgrade Kubernetes Version

Edit `terraform/environments/[env]/terraform.tfvars`:
```hcl
eks_version = "1.31"
```

Then:
```bash
terraform apply -var-file=terraform.tfvars
```

### Add New Environment

Create `terraform/environments/new-env/`:
1. Copy backend.tf, providers.tf, versions.tf from dev
2. Update backend bucket name
3. Create main.tf using dev as template
4. Create variables.tf (can copy from dev)
5. Create terraform.tfvars with new-env specific values
6. Run `terraform init` and `terraform apply`

## Migration from Old Structure

If migrating from non-modular Terraform:

1. Review old resource definitions
2. Group resources into logical modules (VPC, EKS, Nodes, etc.)
3. Create module variables for all hardcoded values
4. Create environment directories with main.tf calling modules
5. Use `terraform state mv` to migrate resources without destroying
6. Validate new structure before removing old code

## File Organization Summary

| Path | Purpose | Audience |
|------|---------|----------|
| `terraform/modules/*/main.tf` | Resource definitions | DevOps engineers |
| `terraform/modules/*/variables.tf` | Module inputs | DevOps engineers |
| `terraform/modules/*/outputs.tf` | Module outputs | DevOps engineers |
| `terraform/modules/*/README.md` | Module docs | All users |
| `terraform/environments/[env]/backend.tf` | State backend | Infrastructure team |
| `terraform/environments/[env]/providers.tf` | AWS provider config | Infrastructure team |
| `terraform/environments/[env]/main.tf` | Module composition | DevOps engineers |
| `terraform/environments/[env]/variables.tf` | Input variables | DevOps engineers |
| `terraform/environments/[env]/terraform.tfvars` | Configuration values | Operators |
| `terraform/environments/[env]/outputs.tf` | Environment outputs | Operators |

## Next Steps

1. **Initialize Dev Environment**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform validate
   terraform plan -var-file=terraform.tfvars
   terraform apply -var-file=terraform.tfvars
   ```

2. **Verify Dev Cluster**
   ```bash
   aws eks update-kubeconfig --name myapp-dev-eks
   kubectl get nodes
   ```

3. **Deploy Staging** (same steps as dev)

4. **Deploy Production** (same steps, with additional approval)

## Conclusion

This fully modularized architecture provides:
- Clear separation between reusable code (modules) and configuration (environments)
- Complete isolation between environments
- Easy to understand and maintain
- Production-ready security defaults
- Scalable for adding new environments or regions
