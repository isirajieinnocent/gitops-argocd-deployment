module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    spot_workers = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      capacity_type  = "SPOT"
      instance_types = ["t3.medium", "t3a.medium"]

      labels = {
        workload-type = "spot"
      }

      # Taints removed
    }
  }

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}
