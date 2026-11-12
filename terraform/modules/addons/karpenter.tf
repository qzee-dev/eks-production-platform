locals {
  karpenter_node_role_name       = substr("${var.cluster_name}-karpenter-node", 0, 64)
  karpenter_controller_role_name = substr("${var.cluster_name}-karpenter-controller", 0, 64)
  karpenter_policy_name          = substr("${var.cluster_name}-karpenter-controller", 0, 128)
  karpenter_queue_name           = substr("${var.cluster_name}-karpenter", 0, 80)

  karpenter_interruption_events = {
    spot_interruption = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Spot Instance Interruption Warning"]
    }
    rebalance_recommendation = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance Rebalance Recommendation"]
    }
    instance_state_change = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance State-change Notification"]
      detail = {
        state = ["stopping", "terminated"]
      }
    }
    scheduled_change = {
      source      = ["aws.health"]
      detail-type = ["AWS Health Event"]
      detail = {
        service           = ["EC2"]
        eventTypeCategory = ["scheduledChange"]
      }
    }
  }
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "karpenter_controller_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole", "sts:TagSession"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["karpenter"]
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

resource "aws_iam_role" "karpenter_controller" {
  name               = local.karpenter_controller_role_name
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_trust.json

  tags = merge(var.tags, {
    Name        = "${var.cluster_name}-karpenter-controller"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

data "aws_iam_policy_document" "karpenter_controller" {
  statement {
    sid    = "AllowReferencedLaunchResources"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:RunInstances",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}::image/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}::snapshot/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:capacity-reservation/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:placement-group/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
    ]
  }

  statement {
    sid    = "AllowTaggedLaunchTemplates"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:RunInstances",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid    = "RegionalResourceDiscovery"
    effect = "Allow"
    actions = [
      "ec2:DescribeCapacityReservations",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribePlacementGroups",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "pricing:GetProducts",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "ReadEKSCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = ["arn:${data.aws_partition.current.partition}:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"]
  }

  statement {
    sid       = "ReadOptimizedAMIs"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}::parameter/aws/service/*"]
  }

  statement {
    sid    = "LaunchTaggedInstances"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.cluster_name]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid    = "TagResourcesOnLaunch"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:fleet/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:spot-instances-request/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.cluster_name]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
    }
  }

  statement {
    sid    = "TerminateTaggedInstances"
    effect = "Allow"
    actions = [
      "ec2:DeleteLaunchTemplate",
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid       = "PassKarpenterNodeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.karpenter_node.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "ec2.amazonaws.com.cn"]
    }
  }

  statement {
    sid       = "CreateTaggedInstanceProfiles"
    effect    = "Allow"
    actions   = ["iam:CreateInstanceProfile"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.cluster_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid    = "ManageTaggedInstanceProfiles"
    effect = "Allow"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
    ]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/eks:eks-cluster-name"
      values   = [var.cluster_name]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid       = "TagOwnedInstanceProfiles"
    effect    = "Allow"
    actions   = ["iam:TagInstanceProfile"]
    resources = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.cluster_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid       = "ListInstanceProfiles"
    effect    = "Allow"
    actions   = ["iam:ListInstanceProfiles"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadInterruptionQueue"
    effect    = "Allow"
    actions   = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage"]
    resources = [aws_sqs_queue.karpenter_interruption.arn]
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  name   = local.karpenter_policy_name
  policy = data.aws_iam_policy_document.karpenter_controller.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

resource "aws_iam_role" "karpenter_node" {
  name = local.karpenter_node_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name        = local.karpenter_node_role_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ])

  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.value
}

resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"
  tags          = var.tags
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller.arn

  depends_on = [aws_eks_addon.pod_identity_agent]
}

resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = local.karpenter_queue_name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags                      = var.tags
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each = local.karpenter_interruption_events

  name          = "${substr(var.cluster_name, 0, 25)}-kp-${each.key}"
  event_pattern = jsonencode(each.value)
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each = aws_cloudwatch_event_rule.karpenter_interruption

  rule      = each.value.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}

data "aws_iam_policy_document" "karpenter_interruption_queue" {
  statement {
    sid    = "AllowEventBridgeToSendInterruptionEvents"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for rule in aws_cloudwatch_event_rule.karpenter_interruption : rule.arn]
    }
  }

  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.karpenter_interruption.arn]
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  policy    = data.aws_iam_policy_document.karpenter_interruption_queue.json
}

resource "helm_release" "karpenter_crds" {
  name             = "karpenter-crd"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter-crd"
  version          = var.karpenter_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    terraform_data.system_node_group_ready,
  ]
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 900

  values = [yamlencode({
    replicas = 2
    serviceAccount = {
      create = true
      name   = "karpenter"
    }
    settings = {
      clusterName       = var.cluster_name
      clusterEndpoint   = data.aws_eks_cluster.this.endpoint
      interruptionQueue = aws_sqs_queue.karpenter_interruption.name
    }
    nodeSelector = {
      "platform.myapp.io/pool" = "system"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    controller = {
      resources = {
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }
  })]

  depends_on = [
    aws_eks_pod_identity_association.karpenter,
    aws_eks_access_entry.karpenter_nodes,
    aws_iam_role_policy_attachment.karpenter_controller,
    helm_release.karpenter_crds,
  ]
}

resource "helm_release" "karpenter_resources" {
  name      = "karpenter-resources"
  chart     = "${path.module}/charts/karpenter-resources"
  namespace = "kube-system"
  wait      = true
  timeout   = 600

  values = [yamlencode({
    clusterName = var.cluster_name
    nodeRole    = local.karpenter_node_role_name
    amiAlias    = var.karpenter_ami_alias
    cpuLimit    = tostring(var.karpenter_cpu_limit)
    zones       = var.availability_zones
    environment = var.environment
    project     = var.project_name
    owner       = var.owner
    costCenter  = var.cost_center
  })]

  depends_on = [helm_release.karpenter]
}
