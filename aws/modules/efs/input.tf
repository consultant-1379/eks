##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# Variables declarations that are passed from the component.

variable "environment_name" {}

variable "component_name" {}

variable "enabled" {
  type        = "string"
  description = "Set to false to prevent the module from creating any resources"
  default     = "true"
}

variable "namespace" {
  type        = "string"
  description = "Namespace name"
  default     = "enm"
}

variable "name" {
  type        = "string"
  description = "Name (_e.g._ `app`)"
  default     = "Ericloud"
}

variable "delimiter" {
  type        = "string"
  description = "Delimiter to be used between `namespace`, `stage`, `name` and `attributes`"
  default     = "-"
}

variable "attributes" {
  type        = "list"
  description = "Additional attributes (e.g. `1`)"
  default     = []
}

variable "tags" {
  type        = "map"
  description = "Additional tags (e.g. `{ BusinessUnit = \"XYZ\" }`"

  default = {
    created-by = "Terraform"
  }
}

variable "encrypted" {
  type        = "string"
  description = "If true, the disk will be encrypted"
  default     = "false"
}

variable "performance_mode" {
  type        = "string"
  description = "The file system performance mode. can be either `generalPurpose` or `maxIO`"
  default     = "generalPurpose"
}

variable "provisioned_throughput_in_mibps" {
  default     = 0
  description = "The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned"
}

variable "throughput_mode" {
  type        = "string"
  description = "Throughput mode for the file system. Defaults to bursting. Valid values: bursting, provisioned. When using provisioned, also set provisioned_throughput_in_mibps"
  default     = "bursting"
}

variable "mount_target_ip_address" {
  type        = "string"
  description = "The address (within the address range of the specified subnet) at which the file system may be mounted via the mount target"
  default     = ""
}

variable "availability_zones" {
  type        = "list"
  description = "Availability Zone IDs"
}

variable "subnets" {
  type        = "list"
  description = "Subnet IDs"
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID"
}

variable "security_groups" {
  type        = "list"
  description = "Security group IDs to allow access to the EFS"
}
