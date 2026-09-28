# EBS CSI Pod Identity
resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name             = var.cluster_name
  namespace                = "kube-system"
  service_account_name     = "ebs-csi-controller-sa"
  role_arn                 = aws_iam_role.ebs_csi.arn
}
