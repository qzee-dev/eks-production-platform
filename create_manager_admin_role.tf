resource "aws_iam_role" "eks_admin"{
    name = "eks_admin_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            }
        }
        ]
    })
  
}

resource "aws_iam_policy" "eks_admin" {
  name = "eks-admin-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "eks.amazonaws.com"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_admin" {
    role =  aws_iam_role.eks_admin.name
    policy_arn = aws_iam_policy.eks_admin.arn
  
}

resource "aws_iam_user" "manager" {
    name = "manager"
  
}
#By attaching the eks_assume_admin policy to the manager user, we are granting the manager user the necessary permissions to assume the,
#eks_admin role. This allows the manager to gain administrative privileges on the EKS cluster by assuming the eks_admin role when needed.

resource "aws_iam_policy" "eks_assume_admin" {
    name = "AmazonEKSAssumeAdminPolicy"
  
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${aws_iam_role.eks_admin.arn}"
    }
  ]
  
}

POLICY
}
#By attaching the eks_assume_admin policy to the manager user, we are granting the manager user the necessary permissions to assume the,
#eks_admin role. This allows the manager to gain administrative privileges on the EKS cluster by assuming the eks_admin role when needed.

resource "aws_iam_user_policy_attachment" "manager" {
    user = aws_iam_user.manager.name
    policy_arn = aws_iam_policy.eks_assume_admin.arn
  
}

#By attaching the admin role to the EKS cluster, we are granting the manager user permissions to perform administrative tasks on the cluster. The manager can assume the admin role to gain full access to the EKS cluster and manage it effectively.
resource "aws_eks_access_entry" "admin_role" {
    cluster_name =  aws_eks_cluster.eks_cluster.name
    principal_arn = aws_iam_role.eks_admin.arn
    kubernetes_groups = [ "my-admin" ]
    
  
}
