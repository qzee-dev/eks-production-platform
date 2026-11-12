locals {
  team_namespaces = distinct(concat(
    var.devops_namespaces,
    var.developer_namespaces,
    var.read_only_namespaces,
  ))

  core_addon_names = toset([
    "vpc-cni",
    "kube-proxy",
    "coredns",
    "aws-ebs-csi-driver",
    "eks-pod-identity-agent",
  ])
}

resource "terraform_data" "validate_team_namespaces" {
  input = local.team_namespaces

  lifecycle {
    precondition {
      condition = length(local.team_namespaces) > 0 && alltrue([
        for namespace in local.team_namespaces :
        length(trimspace(namespace)) > 0 &&
        !strcontains(namespace, "REPLACE_WITH") &&
        !contains(["default", "kube-system", "kube-public", "kube-node-lease"], namespace)
      ])
      error_message = "Use real application namespaces; do not grant team roles access to Kubernetes system namespaces."
    }
  }
}

resource "terraform_data" "system_node_group_ready" {
  input = var.system_node_group_name
}

data "aws_eks_addon_version" "latest_compatible" {
  for_each = {
    for name in local.core_addon_names : name => name
    if !contains(keys(var.addon_versions), name)
  }
  addon_name         = each.value
  kubernetes_version = var.cluster_version
  most_recent        = true
}

resource "terraform_data" "validate_addon_versions" {
  input = var.addon_versions

  lifecycle {
    precondition {
      condition = alltrue([
        for addon_name, version in var.addon_versions :
        contains(local.core_addon_names, addon_name) && length(trimspace(version)) > 0
      ])
      error_message = "addon_versions must contain only supported EKS add-on names with non-empty versions."
    }
  }
}

resource "terraform_data" "validate_karpenter_version" {
  input = var.cluster_version

  lifecycle {
    precondition {
      condition     = tonumber(split(".", var.cluster_version)[1]) >= 31
      error_message = "Karpenter 1.15.x requires Kubernetes 1.31 or newer. Upgrade EKS one minor version at a time."
    }

    precondition {
      condition     = var.karpenter_cpu_limit >= 1
      error_message = "Set a positive Karpenter CPU limit to cap application node growth."
    }
  }
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = var.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = contains(keys(var.addon_versions), "eks-pod-identity-agent") ? var.addon_versions["eks-pod-identity-agent"] : data.aws_eks_addon_version.latest_compatible["eks-pod-identity-agent"].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = var.tags

  depends_on = [
    terraform_data.validate_addon_versions,
    terraform_data.system_node_group_ready,
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = var.cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = contains(keys(var.addon_versions), "vpc-cni") ? var.addon_versions["vpc-cni"] : data.aws_eks_addon_version.latest_compatible["vpc-cni"].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = var.tags

  depends_on = [
    terraform_data.validate_addon_versions,
    terraform_data.system_node_group_ready,
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = contains(keys(var.addon_versions), "kube-proxy") ? var.addon_versions["kube-proxy"] : data.aws_eks_addon_version.latest_compatible["kube-proxy"].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = var.tags

  depends_on = [
    terraform_data.validate_addon_versions,
    terraform_data.system_node_group_ready,
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = contains(keys(var.addon_versions), "coredns") ? var.addon_versions["coredns"] : data.aws_eks_addon_version.latest_compatible["coredns"].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    computeType  = "EC2"
    replicaCount = var.environment == "production" ? 3 : 2
    nodeSelector = {
      "platform.myapp.io/pool" = "system"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    resources = {
      requests = {
        cpu    = "100m"
        memory = "70Mi"
      }
    }
  })

  tags = var.tags

  depends_on = [
    terraform_data.validate_addon_versions,
    terraform_data.system_node_group_ready,
  ]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = contains(keys(var.addon_versions), "aws-ebs-csi-driver") ? var.addon_versions["aws-ebs-csi-driver"] : data.aws_eks_addon_version.latest_compatible["aws-ebs-csi-driver"].version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = var.tags

  depends_on = [
    aws_eks_pod_identity_association.ebs_csi,
    terraform_data.validate_addon_versions,
    terraform_data.system_node_group_ready,
  ]
}
