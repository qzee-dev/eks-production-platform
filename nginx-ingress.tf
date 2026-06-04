resource "helm_release" "external_nginx" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.1"

  
  values = [file("${path.module}/values/nginx-ingress-values.yaml")]

  depends_on = [ helm_release_aws.lbc ]
  
}
