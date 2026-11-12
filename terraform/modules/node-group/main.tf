resource "aws_iam_role" "node" {
  name = "${var.project_name}-${var.environment}-${var.node_group_name}-role"

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

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.node_group_name}-role"

    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.project_name}-${var.environment}-${var.node_group_name}-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, var.tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, var.tags)
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  version         = var.cluster_version

  instance_types = var.instance_types
  capacity_type  = var.capacity_type

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = tostring(aws_launch_template.this.latest_version)
  }

  labels = var.labels

  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-${var.node_group_name}"
    },
    var.tags
  )
}

output "node_group_name" {
  description = "The EKS managed node group name"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  description = "The node IAM role ARN"
  value       = aws_iam_role.node.arn
}
