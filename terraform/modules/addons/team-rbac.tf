resource "helm_release" "team_rbac" {
  name             = "team-rbac"
  chart            = "${path.module}/charts/team-rbac"
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [yamlencode({
    namespaces          = local.team_namespaces
    devopsNamespaces    = var.devops_namespaces
    developerNamespaces = var.developer_namespaces
    readOnlyNamespaces  = var.read_only_namespaces
    kubernetesVersion   = var.cluster_version
    tags                = var.tags
  })]

  depends_on = [
    terraform_data.validate_team_namespaces,
    terraform_data.system_node_group_ready,
  ]
}
