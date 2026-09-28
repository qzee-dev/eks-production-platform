resource "aws_eks_pod_identity_association" "aws_lbc" {
  count                    = var.enable_aws_lbc ? 1 : 0
  cluster_name             = var.cluster_name
  namespace                = "kube-system"
  service_account_name     = "aws-load-balancer-controller"
  role_arn                 = aws_iam_role.aws_lbc[0].arn
}

resource "helm_release" "aws_lbc" {
  count            = var.enable_aws_lbc ? 1 : 0
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "2.6.2"
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  depends_on = [aws_eks_pod_identity_association.aws_lbc]
}
