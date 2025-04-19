resource "null_resource" "cluster_ready" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<EOF
      until curl -k -s ${module.eks.cluster_endpoint}/healthz >/dev/null; do
        echo "Waiting for EKS API server to become healthy..."
        sleep 10
      done
      echo "EKS cluster is ready!"
    EOF
  }
}