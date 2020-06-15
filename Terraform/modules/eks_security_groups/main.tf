# Security Groups for the cluster and nodes.
# Best practices from AWS are listed here - https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html

# Cluster security group + rules.
resource "aws_security_group" "cluster" {
  name        = "${var.name_prefix}-cluster-security-group"
  description = "Cluster-level security group."
  vpc_id      = var.vpc_id

  tags = {
    "Name" = "${var.name_prefix}-cluster-security-group"
  }
}

resource "aws_security_group_rule" "cluster_worker_ingress" {
  type = "ingress"

  description = "Allow cluster ingress from workers/nodes."

  from_port = "0"
  to_port   = "0"
  protocol  = "-1"

  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "cluser_egress" {
  type = "egress"

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "cluser_ingress_self" {
  type = "ingress"

  description = "Allow self-ingress."

  from_port = "0"
  to_port   = "0"
  protocol  = "-1"

  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.cluster.id
}

# Worker security group + rules.
resource "aws_security_group" "worker" {
  name        = "${var.name_prefix}-worker-security-group"
  description = "Worker-level security group."
  vpc_id      = var.vpc_id

  tags = {
    "Name" = "${var.name_prefix}-worker-security-group",
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "worker_to_worker_ingress" {
  type = "ingress"

  description = "Allows node-node communication."

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"

  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.worker.id
}

resource "aws_security_group_rule" "woker_cluster_ingress" {
  type = "ingress"

  description = "Allows worker ingress from the cluster."

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"

  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.worker.id
}

resource "aws_security_group_rule" "worker_egress" {
  type = "egress"

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.worker.id
}

# Security group rules for the cluster-generated security group are in /modules/eks_cluster/main.tf
