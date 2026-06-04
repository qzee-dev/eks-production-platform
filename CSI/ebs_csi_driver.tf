data "aws_iam_policy_document" "ebs_csi_driver"{

    statement {
        effect = "Allow"

        principals {
          type =   "service"
          identifiers =  "pods.eks.amazonaws.com"
        }
    
        actions = [
        "sts:Assumerole",
        "sts:TagSession"
        
        ]
    
        resources = ["*"]
    }
  
}

=================================================
#iam role to use the policy 
=================================================
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${aws_eks_cluster.eks_cluster.name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}


resource "aws_iam_policy"  "ebs_csi_driver_encryption" {
  name        = "${aws_eks_cluster.eks_cluster.name}-ebs-csi-driver-encryption"
  description = "Policy to allow EBS CSI Driver to use KMS keys for encryption"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKeywithoutPlaintext",
          "kms:DescribeKey"
          "kms:createGrant"
        ],
        Resource = "*"
      }
    ]
  })
}



