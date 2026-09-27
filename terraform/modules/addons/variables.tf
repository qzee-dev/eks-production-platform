variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version used by the cluster"
  type        = string
}

variable "tags" {
  description = "Tags to apply to add-ons"
  type        = map(string)
  default     = {}
}

variable "depends_on" {
  description = "Dependency list for add-ons"
  type        = list(any)
  default     = []
}
