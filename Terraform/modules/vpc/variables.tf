# Variables For the VPC itself.

# Name of the VPC.
variable "name" {
  type    = string
  default = "eks"
}

# Name of the EKS cluster.
# This is used for subnet tagging and rendering the external-dns template.
# This is passed via the terraform.tfvars file.
variable "eks_cluster_name" {
  type    = string
  default = "primary"
}

# CIDR block associated with the VPC.
variable "vpc_cidr_block" {
  type    = string
  default = "172.31.0.0/16"
}

# Shared vs dedicated hardware.
# This is described here - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/dedicated-instance.html
variable "instance_tenancy" {
  type    = string
  default = "default"
}

# Name of the hosted zone for the Route 53 private hosted zone.
# This is passed via the terraform.tfvars file.
variable "hosted_zone_name" {
  type    = string
  default = "default"
}

# Variables for subnets.
# These shouldn't require additional explanation.
variable "private_subnet_cidrs" {
  type    = list
  default = []
}
variable "private_subnet_azs" {
  type    = list
  default = []
}

variable "public_subnet_cidrs" {
  type    = list
  default = []
}
variable "public_subnet_azs" {
  type    = list
  default = []
}
