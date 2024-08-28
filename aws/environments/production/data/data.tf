##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# AWS Provider definition.
provider "aws" {
  profile                 = "${var.profile}"
  shared_credentials_file = "${var.public-key}"
  region                  = "${var.aws-region}"
}

# Make a single call to the component module in the modules folder of this repo.
module "data" {
  source                      = "../../../modules/storage"
  standard_storage_class_name = "${var.standard_storage_class_name}"
}

# The "access_token" parameter is left here for completeness, but should be set as the CONSUL_HTTP_TOKEN environment variable
/*terraform {
  backend "consul" {
    address      = "localhost:8500"
    path         = "terraform-remote-state/production/eks"
    access_token = ""
  }
}*/

