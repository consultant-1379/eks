##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# Definition of the worker nodes in the ENM EKS cluster.

locals {
  asw_security_group_name       = "${local.cluster-name}-eks-enm-worker-sg-${random_string.generator.result}"
  aws_iam_role_name             = "${local.cluster-name}-eks-worker-role-${random_string.generator.result}"
  aws_iam_instance_profile_name = "${local.cluster-name}-eks-enm-node-instance-profile-${random_string.generator.result}"
  aws_autoscaling_group_enm     = "${local.cluster-name}-eks-enm-asg-${random_string.generator.result}"
}

# EKS worker role.
resource "aws_iam_role" "worker" {
  name = "${local.aws_iam_role_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attach EKS worket node policies to the EKS cluster role.
resource "aws_iam_role_policy_attachment" "worker-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.worker.name}"
}

# Attach EKS CNI policies to the EKS cluster role.
resource "aws_iam_role_policy_attachment" "worker-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.worker.name}"
}

# Attach EC2 container registry policies to the EKS cluster role.
resource "aws_iam_role_policy_attachment" "worker-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.worker.name}"
}

resource "aws_iam_instance_profile" "worker" {
  name = "${local.aws_iam_instance_profile_name}"
  role = "${aws_iam_role.worker.name}"
}

resource "aws_security_group" "worker" {
  name        = "${local.asw_security_group_name}"
  description = "Security group for all worker nodes in the cluster"
  vpc_id      = "${aws_vpc.enm.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${local.asw_security_group_name}",
     "kubernetes.io/cluster/${local.cluster-name}", "owned"
     )
  }"
}

# Rule to allow worker nodes to communicate with each other.
resource "aws_security_group_rule" "worker-ingress" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.worker.id}"
  source_security_group_id = "${aws_security_group.worker.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# Rule to allow master nodes to communicate with worker nodes.
resource "aws_security_group_rule" "worker-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.worker.id}"
  source_security_group_id = "${aws_security_group.cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# Rule to allow ssh to worker nodes
resource "aws_security_group_rule" "worker-ingress-workstation-ssh" {
  cidr_blocks       = ["${local.workstation-external-cidr}"]
  description       = "Allow workstation to ssh into worker nodes"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.worker.id}"
  to_port           = 22
  type              = "ingress"
}

# AMI definition for worker instances.
data "aws_ami" "eks-worker-ami" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes-version}-*"]
  }

  most_recent = true
  owners      = ["602401143452"]
}

data "aws_region" "current" {}

# Configure Kubernetes applications on the EC2 instance according to the cloudformation version.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  worker-userdata = <<USERDATA
#!/bin/bash

set -o xtrace

/etc/eks/bootstrap.sh \
    --apiserver-endpoint '${aws_eks_cluster.enm.endpoint}' \
    --b64-cluster-ca '${aws_eks_cluster.enm.certificate_authority.0.data}' \
    '${local.cluster-name}'

USERDATA
}

# Launch configuration definition for the workers.
resource "aws_launch_configuration" "enm" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.worker.name}"
  image_id                    = "${data.aws_ami.eks-worker-ami.id}"
  instance_type               = "${var.worker-instance-type}"
  name_prefix                 = "${local.cluster-name}-eks-enm-"
  security_groups             = ["${aws_security_group.worker.id}"]
  user_data_base64            = "${base64encode(local.worker-userdata)}"
  key_name                    = "${aws_key_pair.eks.key_name}"

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling group definition for the workers.
resource "aws_autoscaling_group" "enm" {
  name                 = "${local.aws_autoscaling_group_enm}"
  desired_capacity     = "${var.desired-capacity}"
  launch_configuration = "${aws_launch_configuration.enm.id}"
  max_size             = "${var.max-size}"
  min_size             = "${var.min-size}"
  vpc_zone_identifier  = ["${aws_subnet.enm.*.id}"]

  tag {
    key                 = "Name"
    value               = "${local.aws_autoscaling_group_enm}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
}

resource "local_file" "config-map-aws-auth-file" {

  depends_on = ["aws_autoscaling_group.enm"]

  content  = "${local.config-map-aws-auth}"
  filename = "${path.module}/config-map-aws-auth.yaml"

  provisioner "local-exec" {
    command = <<CMD
kubectl --kubeconfig ~/.kube/${local.cluster-name} apply -f ${path.module}/config-map-aws-auth.yaml;
rm ${path.module}/config-map-aws-auth.yaml
CMD
  }
}

resource "local_file" "worker-validate-script" {
  depends_on = [
    "local_file.config-map-aws-auth-file",
  ]

  content  = "${local.worker_nodes}"
  filename = "${path.module}/worker_validate.sh"

  provisioner "local-exec" {
    command = <<CMD
chmod +x ${path.module}/worker_validate.sh;
bash ${path.module}/worker_validate.sh;
rm ${path.module}/worker_validate.sh

CMD
  }
}

/*
resource "local_file" "helm-service-account-yaml" {
  depends_on = ["local_file.worker-validate-script"]

  content  = "${local.helm-service-account}"
  filename = "${path.module}/helm-service-account.yaml"
}
*/

resource "local_file" "helm" {
  depends_on = ["local_file.worker-validate-script"]

  content  = "${local.tiller}"
  filename = "${path.module}/tiller.sh"

  provisioner "local-exec" {
    command = <<CMD
chmod +x ${path.module}/tiller.sh;
bash ${path.module}/tiller.sh;
rm ${path.module}/tiller.sh
CMD
  }
}

resource "null_resource" "helm-cleanup" {
  provisioner "local-exec" {
    when = "destroy"

    command = <<CMD
helm --kubeconfig ~/.kube/${local.cluster-name} delete guestbook --purge;
kubectl --kubeconfig ~/.kube/${local.cluster-name}  delete deployment,service -n kube-system tiller-deploy
CMD
  }

  depends_on = ["local_file.helm"]
}