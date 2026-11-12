resource "helm_release" "nginx_ingress" {
  count            = var.enable_nginx_ingress ? 1 : 0
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.9.1"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [yamlencode({
    controller = {
      replicaCount = 2
      nodeSelector = {
        "platform.myapp.io/pool" = "system"
      }
      tolerations = [{
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }]
      service = {
        type = "LoadBalancer"
      }
      metrics = {
        enabled = true
      }
    }
  })]

  depends_on = [terraform_data.system_node_group_ready]
}
