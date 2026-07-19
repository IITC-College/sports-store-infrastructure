# EKS control plane, managed node group, and required cluster add-ons. IAM
# roles for the cluster and worker nodes are created by the module (least
# privilege via its built-in AWS managed policy attachments). Per-workload
# AWS permissions (EBS CSI driver, AWS Load Balancer Controller) use EKS Pod
# Identity rather than IRSA — no OIDC provider needed, simpler trust policy.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Grant the identity running `terraform apply` cluster-admin via an EKS
  # access entry, so Task 8's kubectl connectivity check works immediately
  # without a manual aws-auth edit.
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  cluster_addons = {
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    # aws-ebs-csi-driver temporarily removed — recreating to clear a stale
    # serviceAccountRoleArn left over from the IRSA->Pod Identity switch
    # (AWS rejected the in-place update with a "Cross-account pass role"
    # error). Re-added in the very next commit.
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.node_group_capacity_type

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size
    }
  }

  tags = local.tags
}

# Pod Identity role for the EBS CSI driver add-on, scoped to just the EBS
# CSI policy (least privilege) rather than granting volume permissions at
# the node level.
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "${local.name}-ebs-csi"

  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = local.tags
}

# Pod Identity role for the AWS Load Balancer Controller (Stage 5B, Task 4).
# Not a cluster add-on — installed via Helm in sports-store-deployments, but
# the IAM side lives here with the rest of the cluster's IAM roles.
module "lb_controller_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "${local.name}-lb-controller"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = local.tags
}
