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

variable "owner" {
  description = "Owner tag for infrastructure resources"
  type        = string
  default     = "platform-team"
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
  default     = "1.31"
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
