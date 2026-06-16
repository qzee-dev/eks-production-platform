variable "vpc_cidr_block" {
  default = "this is the value for block ip"
}

variable "public_subnet_1a_cidr" {
  default = "this is subnet1 value"

}

variable "public_subnet_1b_cidr" {
  default = "value  for subnet2"

}
variable "private_subnet_1a_cidr" {
  default = "value of subnet3"

}

variable "private_subnet_1b_cidr" {
  default = "value for subnet4"

}

variable "zone1" {
  default = "value for zone1"
}
variable "zone2" {
  default = "value for zone2"
}


variable "env" {
    default = "value for env"
  
}
variable "eks_cluster_version" {
    default = "value for eks cluster version"
  
}

variable "eks_cluster_name" {
    default = "value for eks cluster name"
  
}

variable "instance_type" {
  default = "value for instance_type"
}

variable "node_group_policies" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}


variable "namespace" {
  default = "value for namespace"
  
}
