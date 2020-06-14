terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = ">= 2.0.0"
  }
}

provider "aws" {
  region = var.region
}

# Creates VPC resources.
module "eks_vpc" {
  source = "./modules/vpc"

  name             = "eks"
  eks_cluster_name = var.eks_cluster_name

  vpc_cidr_block   = "172.31.0.0/16"
  instance_tenancy = "default"

  private_subnet_cidrs = ["172.31.0.0/26", "172.31.0.64/26"]
  private_subnet_azs   = ["${var.region}a","${var.region}b"]

  public_subnet_cidrs = ["172.31.1.0/26", "172.31.1.64/26"]
  public_subnet_azs   = ["${var.region}a", "${var.region}b"]

}

# Creates EKS users
module "eks_users" {
  source = "./modules/eks_users"

  name = var.eks_cluster_name
  cluster_name = module.eks_cluster.cluster_name
  cluster_arn = module.eks_cluster.cluster_arn
  worker_role_arn = module.eks_nodes.worker_role_arn
}

# Creates security groups for the cluster
module "eks_sgs" {
  source = "./modules/eks_security_groups"

  name = var.eks_cluster_name
  vpc_id = module.eks_vpc.vpc_id
  user_ip = var.user_ip
}

# Creates the cluster itself
module "eks_cluster" {
  source = "./modules/eks_cluster"

  name                      = var.eks_cluster_name
  worker_subnet_ids         = module.eks_vpc.private_subnet_ids
  cluster_security_group_id = module.eks_sgs.cluster_sg_id
  admin_user_arn            = module.eks_users.admin_user_arn
  worker_sg_id              = module.eks_sgs.worker_sg_id
}

# Creates the nodes/workers for the cluster.
module "eks_nodes" {
  source = "./modules/eks_nodes"

  name = var.eks_cluster_name

  eks_cluster_name             = module.eks_cluster.cluster_name
  eks_cluster_endpoint         = module.eks_cluster.cluster_endpoint
  eks_cluster_authority_data   = module.eks_cluster.cluster_authority_data

  desired_blue_capacity   = "1"
  blue_max_size           = "3"
  blue_min_size           = "1"
  blue_instance_type      = "t3.small"
  blue_kubernetes_version = "1.16"

  desired_green_capacity   = "1"
  green_max_size           = "3"
  green_min_size           = "1"
  green_instance_type      = "t3.small"
  green_kubernetes_version = "1.16"

  worker_security_group_id = module.eks_sgs.worker_sg_id
  private_subnet_ids       = module.eks_vpc.private_subnet_ids
}
