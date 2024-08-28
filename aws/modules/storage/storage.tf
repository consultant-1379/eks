##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# Definition to create a gp2 storage class.

resource "kubernetes_storage_class" "gp2" {
  metadata {
    name = "${var.standard_storage_class_name}"
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters {
    type = "gp2"
  }
}

# Set the created gp2 storage class as default storagecalss.
resource "null_resource" "storage_patch" {
  depends_on = ["kubernetes_storage_class.gp2"]

  provisioner "local-exec" {
    command = "kubectl patch storageclass ${var.standard_storage_class_name} -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}'"
  }
}
