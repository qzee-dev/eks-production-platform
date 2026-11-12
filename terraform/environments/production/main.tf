locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.costcenter
  }
}

module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = var.cluster_name
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  single_nat_gateway   = var.single_nat_gateway
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  cost_center          = var.costcenter
  owner                = var.owner
  tags                 = local.common_tags
}

module "cost_controls" {
  source = "../../modules/cost-controls"

  project_name       = var.project_name
  environment        = var.environment
  monthly_budget_usd = var.monthly_budget_usd
  budget_alert_email = var.budget_alert_email
  tags               = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  project_name                     = var.project_name
  environment                      = var.environment
  owner                            = var.owner
  cost_center                      = var.costcenter
  eks_version                      = var.eks_version
  cluster_name                     = var.cluster_name
  private_subnet_ids               = module.vpc.private_subnet_ids
  vpc_id                           = module.vpc.vpc_id
  cluster_endpoint_public_access   = var.cluster_endpoint_public_access
  cluster_endpoint_private_access  = var.cluster_endpoint_private_access
  public_access_cidrs              = var.public_access_cidrs
  cluster_access_roles             = var.cluster_access_roles
  control_plane_log_retention_days = var.control_plane_log_retention_days
  tags                             = local.common_tags
}

module "node_group" {
  source = "../../modules/node-group"

  project_name    = var.project_name
  environment     = var.environment
  owner           = var.owner
  cost_center     = var.costcenter
  cluster_name    = module.eks.cluster_name
  cluster_version = var.eks_version
  node_group_name = "general"
  subnet_ids      = module.vpc.private_subnet_ids
  instance_types  = var.node_instance_types
  desired_size    = var.desired_size
  min_size        = var.min_size
  max_size        = var.max_size
  capacity_type   = "ON_DEMAND"
  labels          = merge(var.node_labels, { "platform.myapp.io/pool" = "system" })
  tags            = local.common_tags

  depends_on = [module.eks]
}

module "addons" {
  source = "../../modules/addons"

  cluster_name           = module.eks.cluster_name
  cluster_version        = var.eks_version
  system_node_group_name = module.node_group.node_group_name
  project_name           = var.project_name
  environment            = var.environment
  aws_region             = var.region
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  availability_zones     = var.availability_zones
  karpenter_cpu_limit    = var.karpenter_cpu_limit
  karpenter_ami_alias    = var.karpenter_ami_alias
  addon_versions         = var.addon_versions
  enable_aws_lbc         = var.enable_aws_lbc
  enable_cert_manager    = var.enable_cert_manager
  enable_nginx_ingress   = var.enable_nginx_ingress
  enable_metrics_server  = var.enable_metrics_server
  devops_namespaces      = var.devops_namespaces
  developer_namespaces   = var.developer_namespaces
  read_only_namespaces   = var.read_only_namespaces
  cost_center            = var.costcenter
  owner                  = var.owner
  tags                   = local.common_tags

}
