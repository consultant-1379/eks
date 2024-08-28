##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# # Output variables from the module.

output "arn" {
  value       = "${join("", aws_efs_file_system.default.*.arn)}"
  description = "EFS ARN"
}

output "id" {
  value       = "${join("", aws_efs_file_system.default.*.id)}"
  description = "EFS ID"
}

output "mount_target_dns_names" {
  value       = ["${coalescelist(aws_efs_mount_target.default.*.dns_name, list(""))}"]
  description = "List of EFS mount target DNS names"
}

output "mount_target_ids" {
  value       = ["${coalescelist(aws_efs_mount_target.default.*.id, list(""))}"]
  description = "List of EFS mount target IDs (one per Availability Zone)"
}

output "mount_target_ips" {
  value       = ["${coalescelist(aws_efs_mount_target.default.*.ip_address, list(""))}"]
  description = "List of EFS mount target IPs (one per Availability Zone)"
}

output "network_interface_ids" {
  value       = ["${coalescelist(aws_efs_mount_target.default.*.network_interface_id, list(""))}"]
  description = "List of mount target network interface IDs"
}
