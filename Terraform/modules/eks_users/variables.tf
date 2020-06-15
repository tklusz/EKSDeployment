# Prefix used for group and policy creation.
variable "name_prefix" {
  type    = string
  default = "eks"
}

# Used for restricting resource access in the policy template.
# This should be the ARN of the EKS cluster.
variable "cluster_arn" {}

# This is used for rendering aws_auth.yaml.
# This should be the ARN of the role associated with worker nodes.
variable "worker_role_arn" {}
