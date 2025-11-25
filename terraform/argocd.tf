resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.11"
  namespace        = "argocd"
  create_namespace = true

  values = [<<EOF
    server:
      extraArgs:
        - --insecure
      service:
        type: NodePort
        nodePortHttp: 30180
        nodePortHttps: 30181
      ingress:
        enabled: false
    configs:
      cm:
        timeout.reconciliation: 10s
        repo.server.refresh.seconds: 10
    EOF
  ]
}

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "zoo-argocd.duckdns.org"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  values = [<<EOF
    controller:
      service:
        type: NodePort
        nodePorts:
          http: 30080
          https: 30081
    EOF
  ]
}