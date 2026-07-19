variable "aws_region" {
  description = "AWS region to provision the Sports Store infrastructure in."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name, used for tagging and resource naming."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Short project name used as a prefix for resource naming."
  type        = string
  default     = "sports-store"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones to spread public/private subnets across."
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets instead of one per AZ. Cheaper, less resilient to AZ-level NAT failure; the EKS control plane and node groups remain multi-AZ either way."
  type        = bool
  default     = true
}

# --- EKS ---

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "sports-store-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS cluster API server endpoint is publicly accessible (needed for kubectl from outside the VPC, e.g. a student's laptop)."
  type        = bool
  default     = true
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes in the managed node group."
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes in the managed node group."
  type        = number
  default     = 5
}

variable "node_group_capacity_type" {
  description = "Capacity type for the managed node group (ON_DEMAND or SPOT)."
  type        = string
  default     = "ON_DEMAND"
}

# --- ECR ---

variable "ecr_repository_names" {
  description = "Names of the ECR repositories to create, one per application component. Must match the Helm chart's image.repository values (sports-store-deployments/helm/sports-store/values.yaml)."
  type        = list(string)
  default = [
    "sports-store-auth",
    "sports-store-catalog",
    "sports-store-cart",
    "sports-store-order",
    "sports-store-payment",
    "sports-store-gateway",
  ]
}

variable "ecr_image_tag_mutability" {
  description = "Tag mutability setting for ECR repositories. IMMUTABLE enforces the Stage 5B requirement that image tags (semver+git-hash) are never overwritten."
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_untagged_image_expiry_days" {
  description = "Number of days after which untagged ECR images are expired by the lifecycle policy."
  type        = number
  default     = 14
}

variable "ecr_max_tagged_image_count" {
  description = "Maximum number of tagged images to retain per ECR repository before the oldest are expired."
  type        = number
  default     = 20
}
