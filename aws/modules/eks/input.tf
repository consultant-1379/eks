##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# variables declarations that are passed in to the component module from environment folder.

variable "environment-name" {}
variable "component-name" {}
variable "kubernetes-version" {}
variable "worker-instance-type" {}
variable "desired-capacity" {}
variable "max-size" {}
variable "min-size" {}
variable "key-name" {}
variable "vpc-subnet-cidr" {}
variable "cluster-name" {}
variable "public-key" {}
