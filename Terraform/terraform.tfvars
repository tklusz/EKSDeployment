# Name of the EKS cluster. This is also used for other resource names associated with the cluster.
eks_cluster_name = "test"
# Name of the region to create infrastructure in.
# The following aren't compatible due to AZ naming issues - ap-northeast-1; ap-northeast-2; cn-north-1.
# The region must also have EKS enabled.
region = "us-east-1"
# The hosted zone associated with the Route 53 private zone.
hosted_zone_name = "tylerdevops.com"
