# S3 Bucket for Backups
resource "random_id" "velero_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "velero_backups" {
  bucket = "velero-backups-${var.cluster_name}-${random_id.velero_suffix.hex}"
}

resource "aws_s3_bucket_ownership_controls" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Policy for Velero
resource "aws_iam_policy" "velero" {
  name        = "velero-${var.cluster_name}"
  description = "Permissions for Velero backups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.velero_backups.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.velero_backups.arn
      }
    ]
  })
}

# IRSA Module
module "velero_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role                   = true
  role_name                     = "velero-${var.cluster_name}"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.velero.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:velero:velero"]
}

# Kubernetes Namespace
resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

# Helm Release (must come last)
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  namespace  = kubernetes_namespace.velero.metadata[0].name
  version    = "4.0.0"

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.7.0"
  }

  set {
    name  = "backupStorageLocations[0].name"
    value = "aws"
  }

  set {
    name  = "backupStorageLocations[0].provider"
    value = "aws"
  }

  set {
    name  = "backupStorageLocations[0].bucket"
    value = aws_s3_bucket.velero_backups.id
  }

  set {
    name  = "backupStorageLocations[0].config.region"
    value = var.region
  }

  set {
    name  = "volumeSnapshotLocations[0].name"
    value = "aws"
  }

  set {
    name  = "volumeSnapshotLocations[0].provider"
    value = "aws"
  }

  set {
    name  = "volumeSnapshotLocations[0].config.region"
    value = var.region
  }

  set {
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.velero_irsa.iam_role_arn
  }

  depends_on = [
    module.velero_irsa,
    kubernetes_namespace.velero
  ]
}