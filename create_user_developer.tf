resource "aws_iam_user" "developer" {
  name = "developer"
  
}

resource "aws_iam_user_policy" "developer_eks" {
  name   = "AmazonEKSDeveloperPolicy"
  user   = aws_iam_user.developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}



resource "aws_eks_access_entry" "developer" {
    cluster_name =  aws_eks_cluster.eks_cluster.name
    principal_arn = aws_iam_user.developer.arn
    kubernetes_groups = [ "my-viewer" ]

}

