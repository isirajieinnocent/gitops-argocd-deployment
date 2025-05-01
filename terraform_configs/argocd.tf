# Define the Kubernetes namespace resource for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Define the Helm release resource for ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name  # Reference the argocd namespace defined above
  version    = "5.51.6"

  values = [
    <<-EOF
      server:
        service:
          type: clusterIP
          EOF

    ]
}
