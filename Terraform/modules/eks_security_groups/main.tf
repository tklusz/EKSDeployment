# Security Groups for the cluster and nodes.
# AWS best practices are listed here - https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html

# Creating the security_group_rules outside of the SG to avoid cyclic dependencies.
resource "aws_security_group" "cluster" {
  name        = "${var.name}-cluster-security-group"
  description = "Cluster-level security group."
  vpc_id      = var.vpc_id

  tags = {
    "Name" = "${var.name}-cluster-security-group"
  }
}

# This rule would lead to the cyclic dependency.
resource "aws_security_group_rule" "cluster_worker_ingress" {
  type = "ingress"

  description = "Allow cluster ingress from workers/nodes."

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"

  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.worker.id

}

resource "aws_security_group_rule" "cluser_user_ingress" {
  type = "ingress"

  description = "Allow cluster ingress from specified IP."

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["${var.user_ip}/32"]

  security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "cluser_egress" {
  type = "egress"

  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.cluster.id
}

# Leaving this SG as-is, only one needs to change to break the cycle.
resource "aws_security_group" "worker" {
  name        = "${var.name}-worker-security-group"
  description = "Worker-level security group."
  vpc_id      = var.vpc_id

  ingress {
    description = "Allows inter-node communication."

    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"

    self = true
  }

  ingress {
    description = "Allows worker ingress from the cluster."

    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"

    security_groups = [aws_security_group.cluster.id]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${var.name}-worker-security-group"
  }
}
