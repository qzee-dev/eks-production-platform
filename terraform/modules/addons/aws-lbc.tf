resource "aws_eks_pod_identity_association" "aws_lbc" {
  count           = var.enable_aws_lbc ? 1 : 0
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc[0].arn

  depends_on = [aws_eks_addon.pod_identity_agent]
}

resource "helm_release" "aws_lbc" {
  count            = var.enable_aws_lbc ? 1 : 0
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.13.4"
  namespace        = "kube-system"
  create_namespace = false

  values = [yamlencode({
    replicaCount = 2
    vpcId        = var.vpc_id
    nodeSelector = {
      "platform.myapp.io/pool" = "system"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
  })]

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  depends_on = [
    aws_eks_pod_identity_association.aws_lbc,
    aws_iam_role_policy_attachment.aws_lbc,
    terraform_data.system_node_group_ready,
  ]
}
