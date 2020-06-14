# Cluster roles and policy attachments.
# Template file for assuming role.
data "template_file" "cluster_policy_template" {
  template = file("${path.module}/templates/cluster_policy.tpl")

  vars = {
    user_arn = var.admin_user_arn
  }
}

# Creating a role based off the above template.
resource "aws_iam_role" "cluster_role" {
  name               = "${var.name}-cluster-role"
  assume_role_policy = data.template_file.cluster_policy_template.rendered
}

# Adding additional policies to the role.
resource "aws_iam_role_policy_attachment" "cluster_policy_attachment_1" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_policy_attachment_2" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EKS cluster
resource "aws_eks_cluster" "cluster" {
  name     = var.name
  role_arn = aws_iam_role.cluster_role.arn

  vpc_config {
    security_group_ids = [var.cluster_security_group_id]
    subnet_ids         = var.worker_subnet_ids
  }

  # This is explained in Terraform documentation - https://www.terraform.io/docs/providers/aws/r/eks_cluster.html
  # Allows for proper deletion of EKS managed EC2 infrastructure.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy_attachment_1,
    aws_iam_role_policy_attachment.cluster_policy_attachment_2,
  ]
}

# Applying additional security group rules to allow workers + cluster access to the generated SG.

# Rules on the generated security group.
# Required egress rules already exist on the security group when it is generated.
resource "aws_security_group_rule" "generated_cluster_sg_self_ingress" {
  type = "ingress"

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"

  source_security_group_id = var.worker_sg_id
  security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "generated_cluster_sg_ingress_from_provided_cluster_sg" {
  type = "ingress"

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"

  source_security_group_id = var.cluster_security_group_id
  security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

# Rules on the worker security group.
resource "aws_security_group_rule" "worker_ingress_from_generated_cluster_sg" {
  type = "ingress"

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"

  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  security_group_id = var.worker_sg_id
}

# Rules on provided cluster sg.
resource "aws_security_group_rule" "cluster_sg_ingress_from_generated_sg" {
  type = "ingress"

  from_port   = "443"
  to_port     = "443"
  protocol    = "TCP"

  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  security_group_id = var.cluster_security_group_id
}


# Creating cluster_autoscaler.yaml
data "template_file" "cluster_autoscaler_template" {
  template = file("${path.module}/templates/cluster_autoscaler_yaml.tpl")
  vars = {
    cluster_name = aws_eks_cluster.cluster.name
  }
}

# Create local file with rendered cluster_autoscaler template
resource "local_file" "cluster_autoscaler_output" {
  content = data.template_file.cluster_autoscaler_template.rendered
  filename = "${path.root}/cluster_autoscaler.yaml"
}
