output "aws_lbc_role_arn" {
  description = "ARN of AWS Load Balancer Controller IAM role"
  value       = try(aws_iam_role.aws_lbc[0].arn, null)
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of Cluster Autoscaler IAM role"
  value       = try(aws_iam_role.cluster_autoscaler[0].arn, null)
}

output "ebs_csi_role_arn" {
  description = "ARN of EBS CSI Driver IAM role"
  value       = aws_iam_role.ebs_csi.arn
}

output "addons_installed" {
  description = "Map of installed add-ons"
  value = {
    vpc_cni                  = aws_eks_addon.vpc_cni.addon_name
    kube_proxy               = aws_eks_addon.kube_proxy.addon_name
    coredns                  = aws_eks_addon.coredns.addon_name
    ebs_csi_driver           = aws_eks_addon.ebs_csi_driver.addon_name
    aws_lbc                  = var.enable_aws_lbc ? "aws-load-balancer-controller" : null
    cluster_autoscaler       = var.enable_cluster_autoscaler ? "cluster-autoscaler" : null
    cert_manager             = var.enable_cert_manager ? "cert-manager" : null
    nginx_ingress            = var.enable_nginx_ingress ? "nginx-ingress" : null
    metrics_server           = var.enable_metrics_server ? "metrics-server" : null
  }
}
