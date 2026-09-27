# Module: EKS Add-ons

This module installs and manages Amazon EKS add-ons including VPC CNI, CoreDNS, EBS CSI, and kube-proxy.

## Usage

```hcl
module "addons" {
  source = "../../modules/addons"

  cluster_name    = module.eks.cluster_name
  cluster_version = "1.31"
  tags            = local.common_tags
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| cluster_name | string | Yes | - | EKS cluster name |
| cluster_version | string | Yes | - | Kubernetes version |
| tags | map(string) | No | {} | Additional tags for resources |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| addons | map(string) | Map of installed add-ons |
| vpc_cni_status | string | Status of VPC CNI add-on |
| kube_proxy_status | string | Status of kube-proxy add-on |
| coredns_status | string | Status of CoreDNS add-on |
| ebs_csi_driver_status | string | Status of EBS CSI driver add-on |
