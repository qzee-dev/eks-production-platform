resource "helm_release" "metrics_server" {
  count            = var.enable_metrics_server ? 1 : 0
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.13.0"
  namespace        = "kube-system"
  create_namespace = false

  values = [yamlencode({
    replicas = 2
    podDisruptionBudget = {
      enabled = true
    }
    nodeSelector = {
      "platform.myapp.io/pool" = "system"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    resources = {
      requests = {
        cpu    = "100m"
        memory = "200Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "400Mi"
      }
    }
  })]

  depends_on = [terraform_data.system_node_group_ready]
}
