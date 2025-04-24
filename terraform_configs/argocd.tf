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
          type: LoadBalancer
          ports:
            - port: 443
              targetPort: 443
              name: https
        ingress:
          enabled: true
          hosts:
            - argocd.example.com
          tls:
            - secretName: argocd-tls
              hosts:
                - argocd.example.com
    EOF
  ]

  timeout = 600 # Increased to 10 minutes for more time to provision

  depends_on = [
    module.eks,
    kubernetes_namespace.argocd  # Ensure the namespace is created before the Helm release
  ]
}
