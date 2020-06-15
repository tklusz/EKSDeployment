# Prefix used for various resource creation.
variable "name_prefix" {
  type    = string
  default = "eks"
}

# Security group to apply to worker nodes.
# This should be imported from the output of the eks_security_groups module.
variable "worker_security_group_id" {}

# List of IDs of the private subnets.
variable "private_subnet_ids" {
  type = list
}

# Name of the EKS cluster.
variable "eks_cluster_name" {
  type    = string
  default = "primary"
}

# Cluster endpoint and certificate authority data.
variable "eks_cluster_endpoint" {}
variable "eks_cluster_authority_data" {}

# These are all used for configuration of the ASGs.
variable "desired_blue_capacity" {
  type = string
}
variable "blue_max_size" {
  type = string
}
variable "blue_min_size" {
  type = string
}
variable "blue_instance_type" {
  type = string
}
variable "blue_kubernetes_version" {
  type = string
}

variable "desired_green_capacity" {
  type = string
}
variable "green_max_size" {
  type = string
}
variable "green_min_size" {
  type = string
}
variable "green_instance_type" {
  type = string
}
variable "green_kubernetes_version" {
  type = string
}
