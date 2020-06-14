# User's IP address for cluster access.
variable "user_ip"{}
# Name of the EKS cluster. This is also used for other resource names associated with the cluster.
variable "eks_cluster_name" {}
# Name of the region to create infrastructure in.
# The following aren't compatible due to AZ naming issues - ap-northeast-1; ap-northeast-2; cn-north-1;
variable "region" {}
