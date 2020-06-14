# For VPC itself.
variable "vpc_cidr_block" {}
variable "instance_tenancy" {}
variable "name" {}
variable "eks_cluster_name" {}

# For subnets.
variable "private_subnet_cidrs" {
  type = list
  default = []
}
variable "private_subnet_azs" {
  type = list
  default = []
}

variable "public_subnet_cidrs" {
  type = list
  default = []
}
variable "public_subnet_azs" {
  type = list
  default = []
}
