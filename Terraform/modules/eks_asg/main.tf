data "aws_ami" "node_ami" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    # This is the current naming convention for AWS's EKS-optimized Linux AMIs.
    values = ["/aws/service/eks/optimized-ami/${var.kubernetes_version}/amazon-linux-2/recommended/image_id"]
  }
}
