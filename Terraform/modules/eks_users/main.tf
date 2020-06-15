# Creating the IAM accounts for EKS.
# Note that passwords must be manually created for the users on the console.
# We use force_destroy to easily delete the infrastructure when done testing.
resource "aws_iam_user" "cluster_admin" {
  name          = "cluster_admin"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user" "user-1" {
  name          = "user-1"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user" "user-2" {
  name          = "user-2"
  path          = "/"
  force_destroy = true
}

# Adding administrator permissions for EKS admin.
resource "aws_iam_group" "administrator_group" {
  name = "${var.name_prefix}-administrator-group"
}

resource "aws_iam_group_policy_attachment" "admin_group_policy_attachment" {
  group      = aws_iam_group.administrator_group.name
  # This is a built-in policy for administrator access.
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_group_membership" "administrator_group_membership" {
  user   = aws_iam_user.cluster_admin.name
  groups = [aws_iam_group.administrator_group.name]
}

# Adding baseline policies for the other users.
resource "aws_iam_group" "user_group" {
  name = "${var.name_prefix}-user-group"
}

# This uses a template file and renders the values based on the vars block.
data "template_file" "user_policy_template" {
  template = file("${path.module}/templates/user_policy.tpl")

  vars = {
    cluster_arn = var.cluster_arn,
  }
}

resource "aws_iam_policy" "least_privilege_group_policy" {
  name        = "${var.name_prefix}-user-policy"
  description = "Policy used for general access of the cluster."
  policy      = data.template_file.user_policy_template.rendered
}

resource "aws_iam_group_policy_attachment" "user_group_policy_attachment" {
  group      = aws_iam_group.user_group.name
  policy_arn = aws_iam_policy.least_privilege_group_policy.arn
}

resource "aws_iam_group_membership" "user_group_membership" {
  name = "${var.name_prefix}-user-group-membership"

  users = [
    aws_iam_user.user-1.name,
    aws_iam_user.user-2.name,
  ]

  group = aws_iam_group.user_group.name
}

# Auxiliary resources -
# Rendering the aws_base_auth.tpl -> aws_auth.yaml.
data "template_file" "aws_auth_template" {
  template = file("${path.module}/templates/aws_base_auth.tpl")
  vars = {
    worker_role_arn = var.worker_role_arn,
    admin_user_arn  = aws_iam_user.cluster_admin.arn,
    admin_username  = aws_iam_user.cluster_admin.name,
    user_1_arn      = aws_iam_user.user-1.arn,
    user_1_name     = aws_iam_user.user-1.name,
    user_2_arn      = aws_iam_user.user-2.arn,
    user_2_name     = aws_iam_user.user-2.name,
  }
}

resource "local_file" "aws_auth_output" {
  content  = data.template_file.aws_auth_template.rendered
  filename = "${path.root}/aws-auth.yaml"
}
