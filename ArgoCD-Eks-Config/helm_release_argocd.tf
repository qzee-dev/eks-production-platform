===========================================================================
#This installs the core Argo CD platform itself.
# This is the GitOps control plane — it manages your applications, syncs manifests from Git, and deploys them into your cluster.
===============================================================================

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.5.8"

  values = [file("values/argocd.yaml")]

  depends_on = [aws_eks_node_group.general]
}
