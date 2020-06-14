output "worker_sg_id" {
  value = aws_security_group.worker.id
}

output "cluster_sg_id" {
  value = aws_security_group.cluster.id
}
