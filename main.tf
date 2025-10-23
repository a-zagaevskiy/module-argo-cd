provider "kubernetes" {
  cluster_ca_certificate = var.kubernetes_cluster_cert_data
  host                   = var.kubernetes_cluster_endpoint
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = var.yc_exec
    args = [
      "k8s",
      "create-token"
    ]
  }
}

provider "helm" {
  kubernetes = {
    cluster_ca_certificate = var.kubernetes_cluster_cert_data
    host                   = var.kubernetes_cluster_endpoint
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = var.yc_exec
      args = [
        "k8s",
        "create-token"
      ]
    }
  }
}

resource "kubernetes_namespace" "argo-ns" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "msur"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = kubernetes_namespace.argo-ns.metadata[0].name
  version    = "5.46.8" # Рекомендуется указывать версию

  set = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    },
    # Дополнительные настройки для Yandex Cloud
    {
      name  = "controller.metrics.enabled"
      value = "true"
    }
  ]

  depends_on = [
    kubernetes_namespace.argo-ns
  ]
}