# Creating the IAM accounts for EKS.
# Note that passwords must be manually created for the users on the console.
# We use force_destroy to easily delete the infrastructure when done testing.
resource "aws_iam_user" "eks_admin" {
  name          = "${var.name}-cluster-admin"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user" "user_1" {
  name          = "${var.name}-user-1"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user" "user_2" {
  name          = "${var.name}-user-2"
  path          = "/"
  force_destroy = true
}

# Adding adminstrator permissions to EKS admin.
# I'm using a group here as it makes adding future users easier.
resource "aws_iam_group" "administrator_group" {
  name = "${var.name}-administrator-group"
}

resource "aws_iam_group_policy_attachment" "admin_group_policy_attachment" {
  group      = aws_iam_group.administrator_group.name
  # This is a built in policy for Adminstrator access.
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_group_membership" "administrator_group_membership" {
  user = aws_iam_user.eks_admin.name
  groups = [aws_iam_group.administrator_group.name]
}

# We need to create roles and policies for the cluster and workers (nodes).

# Cluster  -
# Template file for assuming role.
data "template_file" "cluster_policy_template" {
  template = file("${path.module}/templates/cluster_policy.tpl")

  vars = {
    user_arn = aws_iam_user.eks_admin.arn
  }
}

# Creating a role based off the above template.
resource "aws_iam_role" "cluster_role" {
  name               = "${var.name}-cluster-role"
  assume_role_policy = data.template_file.cluster_policy_template.rendered
  path          = "/eks/"
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


# Workers/Nodes -
# Template file for assuming role.
data "template_file" "worker_policy_template" {
  template = file("${path.module}/templates/worker_policy.tpl")
}

# Creating a role based off the above template.
resource "aws_iam_role" "worker_role" {
  name               = "${var.name}-worker-role"
  assume_role_policy = data.template_file.worker_policy_template.rendered
  path          = "/eks/"
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

# Instance profile for the workers.
resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "${var.name}-worker_instance_profile"
  role = aws_iam_role.worker_role.name
}
