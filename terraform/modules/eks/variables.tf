variable "project_name" {
  description = "Project name used in naming and tags"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS control plane and worker nodes"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Whether to enable public access to the EKS control plane"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Whether to enable private access to the EKS control plane"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to connect to the public EKS endpoint"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to EKS resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for EKS secrets encryption"
  type        = string
  default     = null
}
