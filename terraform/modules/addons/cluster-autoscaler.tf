resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  count                    = var.enable_cluster_autoscaler ? 1 : 0
  cluster_name             = var.cluster_name
  namespace                = "kube-system"
  service_account_name     = "cluster-autoscaler"
  role_arn                 = aws_iam_role.cluster_autoscaler[0].arn
}

resource "helm_release" "cluster_autoscaler" {
  count            = var.enable_cluster_autoscaler ? 1 : 0
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.29.3"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  depends_on = [aws_eks_pod_identity_association.cluster_autoscaler]
}
