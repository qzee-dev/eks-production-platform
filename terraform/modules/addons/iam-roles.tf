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

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"]
    }
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
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcPeeringConnections",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:DescribeRouteTables",
          "acm:ListCertificates",
          "acm:DescribeCertificate"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ec2:CreateSecurityGroup"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = "CreateSecurityGroup"
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
            "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:targetgroup/*/*"
      },
      {
        Effect   = "Allow"
        Action   = "elasticloadbalancing:AddTags"
        Resource = "*"
        Condition = {
          StringEquals = {
            "elasticloadbalancing:CreateAction" = ["CreateTargetGroup", "CreateLoadBalancer"]
          }
          Null = {
            "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener/net/*/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener/app/*/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener-rule/net/*/*/*",
          "arn:${data.aws_partition.current.partition}:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:listener-rule/app/*/*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  count      = var.enable_aws_lbc ? 1 : 0
  role       = aws_iam_role.aws_lbc[0].name
  policy_arn = aws_iam_policy.aws_lbc[0].arn
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

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"]
    }
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
