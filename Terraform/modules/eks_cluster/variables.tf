# Name of the EKS cluster.
variable "name" {
  type    = string
  default = "primary"
}

# Security group IDs for the cluster SG and worker SG.
# Imported from the eks_security_groups module.
variable "cluster_security_group_id" {}

# Imported from the eks_security_groups module.
variable "worker_security_group_id" {}

# List of subnet IDs where worker nodes are created.
variable "worker_subnet_ids" {
  type = list
}

# ARN of the cluster admin user.
# Imported from the eks_users module.
variable "admin_user_arn" {}
