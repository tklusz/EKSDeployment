# Prefix used for security group creation.
variable "name_prefix" {
  type    = string
  default = "eks"
}

# Name of the EKS cluster.
variable "eks_cluster_name" {
  type    = string
  default = "primary"
}

# This should be the ID of the VPC used to create the cluster.
variable "vpc_id" {}
