# ARN of the role used by worker nodes.
output "worker_role_arn" {
  value = aws_iam_role.worker_role.arn
}
