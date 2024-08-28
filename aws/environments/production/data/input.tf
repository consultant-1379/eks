variable "standard_storage_class_name" {
  type    = "string"
  default = "gp2"
}

variable "public-key" {
  type    = "string"
  default = "~/.ssh/id_rsa.pub"
}

variable "aws-region" {
  default     = "eu-west-1"
  type        = "string"
  description = "The AWS Region to deploy EKS"
}

variable "profile" {
  type    = "string"
  default = "default"
}
