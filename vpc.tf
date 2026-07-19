# Networking for the Sports Store EKS cluster: a VPC spanning
# var.availability_zone_count AZs with public + private subnets, an Internet
# Gateway, and NAT Gateway(s) for private-subnet egress. Subnet tags below are
# required by the AWS VPC CNI / AWS Load Balancer Controller to auto-discover
# where to place ALBs (public) and internal load balancers (private).
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = local.name
  cidr = var.vpc_cidr

  azs = local.azs
  public_subnets = [
    for i in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  private_subnets = [
    for i in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = local.tags
}
