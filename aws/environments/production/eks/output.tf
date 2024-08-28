##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# Output definition for the ENM EKS layer.

output "kubeconfig" {
  value = "${module.eks.kubeconfig}"
}

output "config-map" {
  value = "${module.eks.config-map-aws-auth}"
}

output "cluster-name" {
  value = "${module.eks.cluster-name}"
}