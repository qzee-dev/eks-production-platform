variable "project_name" {
  description = "Project name used in naming and tags"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the managed node group"
  type        = string
}

variable "node_group_name" {
  description = "Name of the managed node group"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets where worker nodes will be placed"
  type        = list(string)
}

variable "instance_types" {
  description = "Instance types used by the worker nodes"
  type        = list(string)
}

variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
}

variable "capacity_type" {
  description = "Node group capacity type"
  type        = string
  default     = "ON_DEMAND"
}

variable "labels" {
  description = "Labels applied to the managed node group"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags applied to the node group"
  type        = map(string)
  default     = {}
}
