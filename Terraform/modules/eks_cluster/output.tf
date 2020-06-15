# Name of the EKS cluster.
output "cluster_name" {
    value = aws_eks_cluster.cluster.name
}

# Cluster's endpoint.
output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

# Certificate authority data from the cluster.
output "cluster_authority_data" {
  value = aws_eks_cluster.cluster.certificate_authority.0.data
}

# Cluster's ARN.
output "cluster_arn" {
    value = aws_eks_cluster.cluster.arn
}
