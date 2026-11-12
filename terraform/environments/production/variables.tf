variable "project_name" {
  description = "Project short name used in resource naming"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway; leave false in production for per-AZ egress resilience"
  type        = bool
  default     = false
}

variable "owner" {
  description = "Owner tag for infrastructure resources"
  type        = string
  default     = "platform-team"
}

variable "costcenter" {
  description = "Cost center responsible for this infrastructure"
  type        = string
  default     = "ENG-001"

}

variable "monthly_budget_usd" {
  description = "Approved monthly production cost alert in USD; zero disables it"
  type        = number
  default     = 0

  validation {
    condition     = var.monthly_budget_usd >= 0
    error_message = "monthly_budget_usd must be zero or a positive amount."
  }
}

variable "budget_alert_email" {
  description = "Email recipient for monthly AWS Budget alerts"
  type        = string
  default     = "REPLACE_WITH_BUDGET_ALERT_EMAIL"

  validation {
    condition = var.monthly_budget_usd == 0 || (
      length(trimspace(var.budget_alert_email)) > 0 &&
      strcontains(var.budget_alert_email, "@")
    )
    error_message = "Set an alert email before enabling the monthly budget."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR for production environment"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.30.11.0/24", "10.30.12.0/24", "10.30.13.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "eks_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.37"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "myapp-production-eks"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the EKS API endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public endpoint"
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "Instance types for managed EKS nodes"
  type        = list(string)
  default     = ["m5.large"]
}

variable "desired_size" {
  description = "Desired managed node count"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum managed node count"
  type        = number
  default     = 3
}

variable "max_size" {
  description = "Maximum managed node count"
  type        = number
  default     = 10
}

variable "node_labels" {
  description = "Labels for EKS node group"
  type        = map(string)
  default = {
    role = "general"
  }
}

variable "cluster_access_roles" {
  description = "Externally managed IAM role ARNs for platform and team access entries"
  type = object({
    platform_automation = string
    cluster_admin       = string
    devops              = string
    developer           = string
    read_only           = string
  })

  validation {
    condition = alltrue([
      for role_arn in values(var.cluster_access_roles) :
      can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:role/.+", role_arn)) &&
      !strcontains(role_arn, "REPLACE_WITH")
    ]) && length(distinct(values(var.cluster_access_roles))) == length(var.cluster_access_roles)
    error_message = "Set five distinct, real IAM role ARNs before planning or applying."
  }
}

variable "devops_namespaces" {
  description = "Namespaces in which the DevOps role receives namespace-admin access"
  type        = list(string)

  validation {
    condition = length(var.devops_namespaces) > 0 && alltrue([
      for namespace in var.devops_namespaces :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", namespace)) &&
      !contains(["default", "kube-system", "kube-public", "kube-node-lease"], namespace)
    ])
    error_message = "Provide one or more valid application namespaces, not Kubernetes system namespaces."
  }
}

variable "developer_namespaces" {
  description = "Namespaces in which developers receive edit access"
  type        = list(string)

  validation {
    condition = length(var.developer_namespaces) > 0 && alltrue([
      for namespace in var.developer_namespaces :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", namespace)) &&
      !contains(["default", "kube-system", "kube-public", "kube-node-lease"], namespace)
    ])
    error_message = "Provide one or more valid application namespaces, not Kubernetes system namespaces."
  }
}

variable "read_only_namespaces" {
  description = "Namespaces in which read-only support roles can view resources"
  type        = list(string)

  validation {
    condition = length(var.read_only_namespaces) > 0 && alltrue([
      for namespace in var.read_only_namespaces :
      can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", namespace)) &&
      !contains(["default", "kube-system", "kube-public", "kube-node-lease"], namespace)
    ])
    error_message = "Provide one or more valid application namespaces, not Kubernetes system namespaces."
  }
}

variable "karpenter_cpu_limit" {
  description = "Maximum aggregate vCPU for Karpenter-managed application nodes"
  type        = number
  default     = 64

  validation {
    condition     = var.karpenter_cpu_limit >= 1
    error_message = "karpenter_cpu_limit must be at least 1 vCPU."
  }
}

variable "karpenter_ami_alias" {
  description = "Approved Karpenter AL2023 AMI alias; pin a release for production"
  type        = string
  default     = "al2023@latest"
}

variable "addon_versions" {
  description = "Optional approved versions keyed by EKS add-on name; empty values select the latest compatible version"
  type        = map(string)
  default     = {}
}

variable "control_plane_log_retention_days" {
  description = "CloudWatch retention for EKS control-plane logs"
  type        = number
  default     = 90
}

variable "enable_aws_lbc" {
  description = "Install AWS Load Balancer Controller; creates AWS load balancer resources"
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Install cert-manager"
  type        = bool
  default     = false
}

variable "enable_nginx_ingress" {
  description = "Install NGINX Ingress; creates a LoadBalancer service"
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Install Metrics Server for HPA resource metrics"
  type        = bool
  default     = true
}
