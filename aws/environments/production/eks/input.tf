##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# Variable definition for the ENM EKS layer.

variable "environment_name" {
  type    = "string"
  default = "production"
}

variable "component_name" {
  type    = "string"
  default = "enm-eks"
}

variable "profile" {
  type = "string"
  default = "default"
}

variable "cluster-name" {
  default     = "ericsson"
  type        = "string"
  description = "The name of your EKS Cluster"
}

variable "aws-region" {
  default     = "eu-west-1"
  type        = "string"
  description = "The AWS Region to deploy EKS"
}

variable "kubernetes-version" {
  default     = "1.11"
  type        = "string"
  description = "Required kubernetes version"
}

variable "vpc-subnet-cidr" {
  default     = "10.0.0.0/16"
  type        = "string"
  description = "The VPC Subnet CIDR"
}

variable "worker-instance-type" {
  default     = "t3.medium"
  type        = "string"
  description = "Worker Node EC2 instance type"
}

variable "desired-capacity" {
  default     = 2
  type        = "string"
  description = "Autoscaling Desired node capacity"
}

variable "max-size" {
  default     = 5
  type        = "string"
  description = "Autoscaling maximum node capacity"
}

variable "min-size" {
  default     = 1
  type        = "string"
  description = "Autoscaling Minimum node capacity"
}

variable "key-name" {
  type    = "string"
  default = "enm-eks-key"
}

variable "public-key" {
  type = "string"
  default = "~/.ssh/id_rsa.pub"
}

