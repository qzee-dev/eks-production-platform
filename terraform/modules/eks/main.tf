resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-cluster-role"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_kms_key" "cluster" {
  description             = "EKS secrets encryption key for ${var.cluster_name}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eks-kms"

    },
    var.tags
  )
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.cluster.key_id
}

resource "terraform_data" "validate_access" {
  input = var.cluster_access_roles

  lifecycle {
    precondition {
      condition = alltrue([
        for role_arn in values(var.cluster_access_roles) :
        can(regex("^arn:(aws|aws-us-gov|aws-cn):iam::[0-9]{12}:role/.+", role_arn)) &&
        !strcontains(role_arn, "REPLACE_WITH")
      ])
      error_message = "Replace every cluster_access_roles placeholder with a real IAM role ARN."
    }

    precondition {
      condition     = length(distinct(values(var.cluster_access_roles))) == length(var.cluster_access_roles)
      error_message = "Each cluster access role must use a distinct IAM role ARN."
    }

  }
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.control_plane_log_retention_days

  tags = merge(local.common_tags, var.tags)
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-sg"
  description = "Security group for the EKS control plane"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
    description = "Allow HTTPS from within the VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name                     = "${var.project_name}-${var.environment}-eks-cluster-sg"
      "karpenter.sh/discovery" = var.cluster_name
    },
    var.tags
  )
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.cluster.arn
    }
    resources = ["secrets"]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  depends_on = [aws_iam_role_policy_attachment.cluster, aws_cloudwatch_log_group.cluster]

  tags = merge(
    local.common_tags,
    {
      Name                     = var.cluster_name
      "karpenter.sh/discovery" = var.cluster_name
    },
    var.tags
  )
}

locals {
  access_entries = {
    platform_automation = var.cluster_access_roles.platform_automation
    cluster_admin       = var.cluster_access_roles.cluster_admin
    devops              = var.cluster_access_roles.devops
    developer           = var.cluster_access_roles.developer
    read_only           = var.cluster_access_roles.read_only
  }

  access_policy_associations = {
    platform_automation = {
      principal_arn = var.cluster_access_roles.platform_automation
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      scope         = "cluster"
      namespaces    = []
    }
    cluster_admin = {
      principal_arn = var.cluster_access_roles.cluster_admin
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      scope         = "cluster"
      namespaces    = []
    }
  }
}

resource "aws_eks_access_entry" "team" {
  for_each = local.access_entries

  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value
  type              = "STANDARD"
  kubernetes_groups = local.access_entry_groups[each.key]

  depends_on = [terraform_data.validate_access]

  tags = merge(local.common_tags, var.tags)
}

locals {
  access_entry_groups = {
    platform_automation = []
    cluster_admin       = []
    devops              = ["eks:devops"]
    developer           = ["eks:developers"]
    read_only           = ["eks:read-only"]
  }
}

resource "aws_eks_access_policy_association" "team" {
  for_each = local.access_policy_associations

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.scope
    namespaces = each.value.scope == "namespace" ? each.value.namespaces : null
  }

  depends_on = [aws_eks_access_entry.team]
}

output "cluster_name" {
  description = "The EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "kms_key_arn" {
  description = "KMS key ARN used for EKS secrets"
  value       = aws_kms_key.cluster.arn
}
