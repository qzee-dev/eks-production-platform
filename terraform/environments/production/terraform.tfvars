project_name                     = "myapp"
environment                      = "production"
region                           = "us-east-1"
owner                            = "platform-team"
vpc_cidr                         = "10.30.0.0/16"
public_subnet_cidrs              = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
private_subnet_cidrs             = ["10.30.11.0/24", "10.30.12.0/24", "10.30.13.0/24"]
availability_zones               = ["us-east-1a", "us-east-1b", "us-east-1c"]
cluster_name                     = "myapp-production-eks"
eks_version                      = "1.37"
cluster_endpoint_public_access   = false
cluster_endpoint_private_access  = true
public_access_cidrs              = []
node_instance_types              = ["m5.large"]
desired_size                     = 3
min_size                         = 3
max_size                         = 10
single_nat_gateway               = false
karpenter_cpu_limit              = 64
control_plane_log_retention_days = 90
monthly_budget_usd               = 0 # Set an approved amount to enable AWS Budget alerts.
budget_alert_email               = "REPLACE_WITH_BUDGET_ALERT_EMAIL"

cluster_access_roles = {
  platform_automation = "arn:aws:iam::111122223333:role/REPLACE_WITH_PLATFORM_AUTOMATION_ROLE"
  cluster_admin       = "arn:aws:iam::111122223333:role/REPLACE_WITH_BREAK_GLASS_ADMIN_ROLE"
  devops              = "arn:aws:iam::111122223333:role/REPLACE_WITH_DEVOPS_ROLE"
  developer           = "arn:aws:iam::111122223333:role/REPLACE_WITH_DEVELOPER_ROLE"
  read_only           = "arn:aws:iam::111122223333:role/REPLACE_WITH_READ_ONLY_ROLE"
}

devops_namespaces    = ["REPLACE_WITH_DEVOPS_NAMESPACE"]
developer_namespaces = ["REPLACE_WITH_APPLICATION_NAMESPACE"]
read_only_namespaces = ["REPLACE_WITH_READ_ONLY_NAMESPACE"]
