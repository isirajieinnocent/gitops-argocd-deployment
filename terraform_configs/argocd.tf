resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  values = [
    <<-EOF
      server:
        service:
          type: LoadBalancer
    EOF
  ]

  timeout = 600 # Increased to 10 minutes for more time to provision

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd
  ]
}
