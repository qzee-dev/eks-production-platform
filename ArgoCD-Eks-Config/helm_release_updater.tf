==================================================================================
#This installs the Argo CD Image Updater component.
#This is the automation agent — it watches container registries (Docker Hub, ECR, etc.), updates Git manifests with new image tags, and triggers Argo CD to redeploy.
=========================================================================================
resource "helm_release" "updater" {
  name = "updater"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true
  version          = "0.12.3"

  values = [file("values/image-updater.yaml")]

  depends_on = [helm_release.argocd]
}
