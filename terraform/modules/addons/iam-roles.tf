# AWS Load Balancer Controller
data "aws_iam_policy_document" "aws_lbc" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  count              = var.enable_aws_lbc ? 1 : 0
  name               = "${var.project_name}-${var.environment}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc.json

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-aws-lbc"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

resource "aws_iam_policy" "aws_lbc" {
  count = var.enable_aws_lbc ? 1 : 0
  name  = "${var.project_name}-${var.environment}-aws-lbc-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elbv2:CreateLoadBalancer",
          "elbv2:DeleteLoadBalancer",
          "elbv2:DescribeLoadBalancers",
          "elbv2:DescribeTargetGroups",
          "elbv2:ModifyLoadBalancerAttributes",
          "elbv2:SetIpAddressType",
          "elasticloadbalancing:*",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:ModifySecurityGroupRules"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  count      = var.enable_aws_lbc ? 1 : 0
  role       = aws_iam_role.aws_lbc[0].name
  policy_arn = aws_iam_policy.aws_lbc[0].arn
}

# Cluster Autoscaler
data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count              = var.enable_cluster_autoscaler ? 1 : 0
  name               = "${var.project_name}-${var.environment}-cluster-autoscaler-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler.json

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cluster-autoscaler"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cluster-autoscaler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes",
          "ec2:GetInstanceTypesFromInstanceRequirements"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

# EBS CSI Driver (Enhanced)
data "aws_iam_policy_document" "ebs_csi" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.project_name}-${var.environment}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi.json

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ebs-csi"
      Environment = var.environment
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
