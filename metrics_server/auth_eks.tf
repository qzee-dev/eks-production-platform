data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks_cluster.name
}
