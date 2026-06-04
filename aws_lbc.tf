data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = Allow

    principals {
      type = "Service"
      identifiers = ["pods.eks.amazon.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  name = "${var.eks_cluster_name}-aws-lbc"

  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json
  
}


resource "aws_iam_policy" "aws_lbc" {
    policy = file("./iam/AWSLoadBalancerControllerPolicy.json")
    name = "AWSLoadBalancerControllerPolicy"
  
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
    role = aws_iam_role.aws_lbc.name
    policy_arn = aws_iam_policy.aws_lbc.arn
  
}


resource "aws_eks_pod_identity_association" "aws_lbc" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    namespace = "kube-system"
    service_account_name = "aws-load-balancer-controller"
    role_arn = aws_iam_role.aws_lbc.arn
}

================================================================
#✅ Helm Release (fixed)
=================================================================
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.7.1" # example (check latest compatible)

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = ["helm_release.cluster_autoscaler"]
  
}