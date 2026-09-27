variable "project_name" {
  description = "Project short name used in resource naming"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"

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

variable "owner" {
  description = "Owner tag for infrastructure resources"
  type        = string
  default     = "platform-team"
}

variable "vpc_cidr" {
  description = "VPC CIDR for staging environment"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "eks_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "myapp-staging-eks"
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
  default     = ["t3.large"]
}

variable "desired_size" {
  description = "Desired managed node count"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum managed node count"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum managed node count"
  type        = number
  default     = 5
}

variable "node_labels" {
  description = "Labels for EKS node group"
  type        = map(string)
  default = {
    role = "general"
  }
}
