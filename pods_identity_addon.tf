/*
#to check for latest addon version
aws eks describe-addon-versions \
--region us-east-02 \
--addon-name eks-pod-identity-agent

##
##kubectl get daemonset eks-pod-identity-agent -n kube-system

*/

resource "aws_eks_addon" "pod_identity" {
    cluster_name = aws_eks_cluster.eks_cluster.name
    addon_name   = "eks-pod-identity-agent"
    addon_version = "v1.2.0-eks-build.1"
  
}

