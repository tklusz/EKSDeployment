variable "name" {}

variable "worker_security_group_id" {}
variable "private_subnet_ids" {}

variable "eks_cluster_name" {}
variable "eks_cluster_endpoint" {}
variable "eks_cluster_authority_data" {}

variable "desired_blue_capacity" {}
variable "blue_max_size" {}
variable "blue_min_size" {}
variable "blue_instance_type" {}
variable "blue_kubernetes_version" {}

variable "desired_green_capacity" {}
variable "green_max_size" {}
variable "green_min_size" {}
variable "green_instance_type" {}
variable "green_kubernetes_version" {}
