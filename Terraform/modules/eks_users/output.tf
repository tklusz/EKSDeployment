# ARN of the admin user.
output "admin_user_arn" {
  value = aws_iam_user.cluster_admin.arn
}
