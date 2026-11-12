variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version used by the cluster"
  type        = string
}

variable "system_node_group_name" {
  description = "Managed node group that hosts system add-ons"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC where the cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets eligible for Karpenter nodes"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones eligible for Karpenter nodes"
  type        = list(string)
}

variable "devops_namespaces" {
  description = "Namespaces in which the DevOps IAM role receives scoped operational access"
  type        = list(string)
}

variable "developer_namespaces" {
  description = "Namespaces in which the developer IAM role receives workload access"
  type        = list(string)
}

variable "read_only_namespaces" {
  description = "Namespaces in which the read-only IAM role can view resources"
  type        = list(string)
}

variable "owner" {
  description = "Team responsible for this platform"
  type        = string
}

variable "cost_center" {
  description = "Cost center responsible for this platform"
  type        = string
}

variable "karpenter_cpu_limit" {
  description = "Maximum aggregate vCPU for Karpenter-managed nodes"
  type        = number
}

variable "karpenter_ami_alias" {
  description = "AL2023 AMI alias used by the Karpenter EC2NodeClass"
  type        = string
}

variable "karpenter_version" {
  description = "Pinned Karpenter controller and CRD chart version"
  type        = string
  default     = "1.15.1"
}

variable "addon_versions" {
  description = "Optional approved versions keyed by EKS add-on name"
  type        = map(string)
  default     = {}
}

variable "enable_aws_lbc" {
  description = "Install AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "enable_cert_manager" {
  description = "Install cert-manager"
  type        = bool
  default     = false
}

variable "enable_nginx_ingress" {
  description = "Install NGINX Ingress Controller"
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Install Metrics Server for HPA resource metrics"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to AWS resources"
  type        = map(string)
  default     = {}
}
