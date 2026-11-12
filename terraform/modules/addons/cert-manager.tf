resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.13.1"
  namespace        = "cert-manager"
  create_namespace = true

  values = [yamlencode({
    replicaCount = 2
    nodeSelector = {
      "platform.myapp.io/pool" = "system"
    }
    tolerations = [{
      key      = "CriticalAddonsOnly"
      operator = "Exists"
      effect   = "NoSchedule"
    }]
    webhook = {
      replicaCount = 2
      nodeSelector = {
        "platform.myapp.io/pool" = "system"
      }
      tolerations = [{
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }]
    }
    cainjector = {
      replicaCount = 2
      nodeSelector = {
        "platform.myapp.io/pool" = "system"
      }
      tolerations = [{
        key      = "CriticalAddonsOnly"
        operator = "Exists"
        effect   = "NoSchedule"
      }]
    }
  })]

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [terraform_data.system_node_group_ready]
}
