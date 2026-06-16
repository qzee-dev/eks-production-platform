=======================================================
#IAM role for cluster
=======================================================
resource "aws_iam_role" "eks" {

    name = "${var.eks_cluster_name}"
    assume_role_policy = <<EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]  
}

EOF
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
  
}
=======================================================
#EKS Cluster (modern style)
=======================================================
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks.arn

  vpc_config {



    endpoint_public_access = true
    endpoint_private_access = false


    subnet_ids = [
        
        aws_subnet.subnet3.id,
        aws_subnet.subnet4.id,  
    ]

  }

  access_config{
    authentication_mode = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on =[
    aws_iam_role_policy_attachment.eks
  ]
}

=======================================================
# IAM role for Node Group
=======================================================
resource "aws_iam_role" "eks_nodes" {
  name = "${var.eks_cluster_name}-nodes"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

=======================================================
# Attach multiple policies using loop
=======================================================
locals {
  node_group_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = toset(local.node_group_policies)

  role       = aws_iam_role.eks_nodes.name
  policy_arn = each.value
}

=======================================================
# Managed Node Group
=======================================================
resource "aws_eks_node_group" "managed_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  version         = var.eks_cluster_version
  node_group_name = "general"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  subnet_ids = [
    aws_subnet.subnet3.id,
    aws_subnet.subnet4.id
  ]


  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
   
   update_config {
    max_unavailable = 1
  }

  labels {
    role = general
  }
  
  instance_types = var.instance_type

  capacity_type = "ON_DEMAND"


  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_policy
  ]

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size]
  }
}
