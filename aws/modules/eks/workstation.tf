##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# Definition related to the workstation machine.

# Used in conjuction with using icanhazip.com to determine
# local workstation external IP to configure inbound
# EC2 Security Group access to the Kubernetes cluster.
provider "http" {}

data "http" "workstation-external-ip" {
  url = "http://icanhazip.com"
}

# Override with variable or hardcoded value if necessary
locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}
