resource "aws_eks_addon" "vpc_cni" {
  cluster_name = var.cluster_name
  addon_name   = "vpc-cni"
  addon_version = null
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"
  addon_version = null
}

resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
  addon_version = null
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = null
}

output "addons" {
  description = "The EKS add-ons installed for the cluster"
  value = {
    vpc_cni       = aws_eks_addon.vpc_cni.addon_name
    kube_proxy    = aws_eks_addon.kube_proxy.addon_name
    coredns      = aws_eks_addon.coredns.addon_name
    ebs_csi_driver = aws_eks_addon.ebs_csi_driver.addon_name
  }
}
