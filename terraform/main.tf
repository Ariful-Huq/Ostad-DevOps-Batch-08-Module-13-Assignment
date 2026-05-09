# terraform/main.tf
############################################
# Availability Zones
############################################
data "aws_availability_zones" "available" {
  state = "available"
}

############################################
# VPC
############################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.1"

  name = "three-tier-vpc"
  cidr = var.vpc_cidr

  azs = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1]
  ]

  public_subnets = [
    "10.50.1.0/24",
    "10.50.2.0/24"
  ]

  private_subnets = [
    "10.50.11.0/24",
    "10.50.12.0/24"
  ]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Project = "three-tier-eks"
    Managed = "terraform"
  }
}

############################################
# EKS
############################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true

  enable_irsa = true

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    workers = {
      desired_size = 2
      min_size     = 2
      max_size     = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      ami_type = "AL2023_x86_64_STANDARD"

      labels = {
        role = "worker"
      }

      tags = {
        Name = "three-tier-worker"
      }
    }
  }

  tags = {
    Project = "three-tier-eks"
    Managed = "terraform"
  }
}
