variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet discovery tags"
  type        = string
}

variable "region" {
  description = "AWS region where the EKS cluster will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the VPC subnets"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway" {
  description = "Create one shared NAT gateway instead of one per public subnet"
  type        = bool
  default     = false
}

variable "cost_center" {
  description = "Cost center responsible for this infrastructure"
  type        = string
}

variable "owner" {
  description = "Team or person responsible for this infrastructure"
  type        = string
}
