##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# All the definition related to the master nodes in the cluster.

locals {
  cluster-name                    = "${var.cluster-name}-${random_string.generator.result}"
  asw_security_group_cluster_name = "${local.cluster-name}-eks-enm-cluster-sg-${random_string.generator.result}"
}

# EKS cluster role.
resource "aws_iam_role" "cluster" {
  name = "${var.cluster-name}-eks-enm-cluster-role-${random_string.generator.result}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach EKS Cluster policies to the EKS cluster role.
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.cluster.name}"
}

# Attach EKS Service policies to the EKS cluster role.
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.cluster.name}"
}

# security group definition for the cluster.
resource "aws_security_group" "cluster" {
  name        = "${local.asw_security_group_cluster_name}"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.enm.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${local.asw_security_group_cluster_name}"
  }
}

# Rule to allow worker nodes to communicate with master nodes on 443.
# this rules applied as minimal inbound security.
# More Info: https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster api server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster.id}"
  source_security_group_id = "${aws_security_group.worker.id}"
  to_port                  = 443
  type                     = "ingress"
}

# Rule to workstation machine to communicate with master nodes on 443.
resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.cluster.id}"
  to_port           = 443
  type              = "ingress"
}

# EKS cluster definition.
resource "aws_eks_cluster" "enm" {
  name     = "${local.cluster-name}"
  role_arn = "${aws_iam_role.cluster.arn}"
  version  = "${var.kubernetes-version}"

  vpc_config {
    security_group_ids = ["${aws_security_group.cluster.id}"]
    subnet_ids         = ["${aws_subnet.enm.*.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy",
  ]
}

resource "null_resource" "kubeconfig-setup" {
  depends_on = ["aws_eks_cluster.enm"]

  provisioner "local-exec" {
    command = "echo '${local.kubeconfig}' > ~/.kube/${local.cluster-name}"
  }
}
