variable "eks_cluster_name" {
  type    = string
  default = "primary"
}
variable "region" {
  type    = string
  default = "us-west-2"
}
variable "hosted_zone_name" {
  type    = string
  default = "tylerdevops.com"
}
