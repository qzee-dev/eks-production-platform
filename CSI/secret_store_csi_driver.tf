resource "helm_release" "secret_csi_driver" {
    name       = "aws-secret-csi-driver"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-secret-csi-driver"
    version    = "0.0.1"
    namespace  = "kube-system"

    #Must be set  if you use Env Variable
    
    set {
        name  = "sync.Secret_enabled "
        value = true


    depends_on = [helm_release.aws_efs_csi_driver]
  
}



resource "helm_release" "secret_csi_driver_aws_provider" {
    name       = "secret-store-csi-driver-aws-provider"


    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-secret-csi-driver-aws-provider"
    version    = "0.0.1"
    namespace  = "kube-system"

     
     }

     depends_on = [helm_release.secret_csi_driver]

  
}

# ===================================================================================================
# the csi policy is used not by csi driver but rather the application that need access to the  secrets
#=====================================================================================================

data "aws_iam_policy_document" "my_app_secrets" {
    statement {
        effect = "Allow"
        actions = [ "AssumeRolewithWebIdentity" ]



    condition {
      test =  "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub"
      values =  "system:serviceaccount:kube-system:aws-secret-csi-driver"
    }


    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type = "fedrated"
    }


        resources = ["*"] # Adjust this to be more specific to your secrets
    }
  
}

resource "aws_iam_role" "myapp_secrets" {
  name = "${aws_eks_cluster.eks.name}-myapp-secrets"

  assume_role_policy = data.aws_iam_policy_document.myapp_secrets.json
}
