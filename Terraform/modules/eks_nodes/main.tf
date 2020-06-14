# Set up roles and policies for worker nodes.
# Template file for assuming role.
data "template_file" "worker_policy_template" {
  template = file("${path.module}/templates/worker_policy.tpl")
}

# Template file and policy for cluster autoscaling.
data "template_file" "autoscaling_policy_template"{
  template = file("${path.module}/templates/autoscaling_policy.tpl")
}

resource "aws_iam_policy" "autoscaling_policy" {
  name = "${var.name}-autoscaling-policy"
  description = "Policy for node autoscaling."
  policy = data.template_file.autoscaling_policy_template.rendered
}

# Creating a role based off the above template.
resource "aws_iam_role" "worker_role" {
  name               = "${var.name}-worker-role"
  assume_role_policy = data.template_file.worker_policy_template.rendered
}

# Adding additional policies to the role.
resource "aws_iam_role_policy_attachment" "worker_policy_attachment_1" {
  role       = aws_iam_role.worker_role.name
  policy_arn ="arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_policy_attachment_2" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "worker_policy_attachment_3" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "autoscaling_policy" {
  role       = aws_iam_role.worker_role.name
  policy_arn = aws_iam_policy.autoscaling_policy.arn
}

# Instance profile for the workers.
resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "${var.name}-worker-instance-profile"
  role = aws_iam_role.worker_role.name
}

# This is required when launching via ASGs.
# Descirbed in more detail here - https://aws.amazon.com/premiumsupport/knowledge-center/eks-worker-nodes-cluster/
locals {
  node_user_data = <<DATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.eks_cluster_name}
DATA
}

# AMI for blue and green worker nodes
data "aws_ami" "blue_node_ami" {
  most_recent = true
  owners = ["self", "amazon"]

  filter {
    name = "name"
    # This is the current naming convention for AWS's EKS-optimized Linux AMIs.
    values = ["amazon-eks-node-${var.blue_kubernetes_version}*"]
  }
}

data "aws_ami" "green_node_ami" {
  most_recent = true
  owners = ["self", "amazon"]

  filter {
    name = "name"
    # This is the current naming convention for AWS's EKS-optimized Linux AMIs.
    values = ["amazon-eks-node-${var.green_kubernetes_version}*"]
  }
}


# Launch configurations for blue and green nodes.
resource "aws_launch_configuration" "blue" {
  name_prefix                 = "${var.name}-eks-launch-config-blue-"
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.worker_instance_profile.name
  user_data_base64     = base64encode(local.node_user_data)
  image_id             = data.aws_ami.blue_node_ami.id
  instance_type        = var.blue_instance_type
  security_groups      = [var.worker_security_group_id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "green" {
  name_prefix                 = "${var.name}-eks-launch-config-green-"
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.worker_instance_profile.name
  user_data_base64    = base64encode(local.node_user_data)
  image_id             = data.aws_ami.green_node_ami.id
  instance_type        = var.green_instance_type
  security_groups      = [var.worker_security_group_id]

  lifecycle {
    create_before_destroy = true
  }
}

# Creating the ASGs.
resource "aws_autoscaling_group" "blue" {
  name                 = "${var.name}-eks-blue-asg"
  launch_configuration =  aws_launch_configuration.blue.id

  desired_capacity = var.desired_blue_capacity
  max_size         = var.blue_max_size
  min_size         = var.blue_min_size

  vpc_zone_identifier = var.private_subnet_ids.*

  tag {
    key                 = "kubernetes.io/cluster/${var.eks_cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
    value  = "owned"
    propagate_at_launch = false
  }

  tag {
    key = "k8s.io/cluster-autoscaler/enabled"
    value  = "true"
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group" "green" {
  name                 = "${var.name}-eks-green-asg"
  launch_configuration =  aws_launch_configuration.green.id

  desired_capacity = var.desired_green_capacity
  max_size         = var.green_max_size
  min_size         = var.green_min_size

  vpc_zone_identifier = var.private_subnet_ids.*

  tag {
    key                 = "kubernetes.io/cluster/${var.eks_cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key = "k8s.io/cluster-autoscaler/${var.eks_cluster_name}"
    value  = "owned"
    propagate_at_launch = false
  }

  tag {
    key = "k8s.io/cluster-autoscaler/enabled"
    value  = "true"
    propagate_at_launch = false
  }
}
