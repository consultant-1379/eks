##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# All the definition related to the EFS.

module "label" {
  source     = "../label"
  enabled    = "${var.enabled}"
  namespace  = "${var.namespace}"
  name       = "${var.name}"
  stage      = "${var.environment_name}"
  delimiter  = "${var.delimiter}"
  attributes = "${var.attributes}"
  tags       = "${var.tags}"
}

resource "null_resource" "efs" {
  provisioner "local-exec" {
    command = "echo You are deploying the ${var.component_name} component into the ${var.environment_name} environment!"
  }
}

resource "aws_efs_file_system" "default" {
  encrypted                       = "${var.encrypted}"
  performance_mode                = "${var.performance_mode}"
  provisioned_throughput_in_mibps = "${var.provisioned_throughput_in_mibps}"
  throughput_mode                 = "${var.throughput_mode}"
  tags                            = "${module.label.tags}"
}

resource "aws_efs_mount_target" "default" {
  count           = "${length(var.availability_zones) > 0 ? length(var.availability_zones) : 0}"
  file_system_id  = "${join("", aws_efs_file_system.default.*.id)}"
  ip_address      = "${var.mount_target_ip_address}"
  subnet_id       = "${element(var.subnets, count.index)}"
  security_groups = ["${join("", aws_security_group.default.*.id)}"]
}

resource "aws_security_group" "default" {
  name        = "${module.label.id}"
  description = "EFS Access"
  vpc_id      = "${var.vpc_id}"
  tags        = "${module.label.tags}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  type      = "ingress"
  from_port = "2049"
  to_port   = "2049"
  protocol  = "tcp"

  source_security_group_id = "${element(compact(var.security_groups), count.index)}"
  security_group_id        = "${aws_security_group.default.id}"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.default.id}"
}
