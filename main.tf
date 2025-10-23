terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
  required_version = ">= 0.14.8"
}

provider "yandex" {
  zone = var.yandex_zone
}

data "yandex_client_config" "client" {}

provider "kubernetes" {
  host                   = var.kubernetes_cluster_endpoint
  cluster_ca_certificate = var.kubernetes_cluster_cert_data
  token                  = data.yandex_client_config.client.iam_token
}

provider "helm" {
  kubernetes = {
    host                   = var.kubernetes_cluster_endpoint
    cluster_ca_certificate = var.kubernetes_cluster_cert_data
    token                  = data.yandex_client_config.client.iam_token
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