output "aws_region" {
  description = "AWS region the infrastructure was provisioned in."
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (EKS nodes, internal load balancers)."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (internet-facing load balancers)."
  value       = module.vpc.public_subnets
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster's Kubernetes API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate data for the EKS cluster's API server."
  value       = module.eks.cluster_certificate_authority_data
}

output "configure_kubectl" {
  description = "Command to update the local kubeconfig to point at this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "lb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller's Pod Identity association (Stage 5B)."
  value       = module.lb_controller_pod_identity.iam_role_arn
}

output "ecr_repository_urls" {
  description = "Map of component name to its ECR repository URL, for Stage 5B image pushes."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}
