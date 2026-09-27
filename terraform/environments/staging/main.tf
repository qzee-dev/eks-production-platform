locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

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

module "eks" {
  source = "../../modules/eks"

  project_name                     = var.project_name
  environment                      = var.environment
  eks_version                      = var.eks_version
  cluster_name                     = var.cluster_name
  private_subnet_ids               = module.vpc.private_subnet_ids
  cluster_endpoint_public_access   = var.cluster_endpoint_public_access
  cluster_endpoint_private_access  = var.cluster_endpoint_private_access
  public_access_cidrs              = var.public_access_cidrs
  vpc_id                          = module.vpc.vpc_id
  tags                            = local.common_tags
}

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

module "addons" {
  source = "../../modules/addons"

  cluster_name = module.eks.cluster_name
  cluster_version = var.eks_version
  tags = local.common_tags
}
