variable "region" {
  type        = string
  description = "AWS region for regional service names and tags."
}

variable "dr_active" {
  type        = bool
  description = "When true, create the second NAT Gateway and route each app subnet to its same-AZ NAT."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the AWS DR VPC."
}

variable "azs" {
  type        = list(string)
  description = "Two availability zones for the DR network."

  validation {
    condition     = length(var.azs) == 2
    error_message = "The network module expects exactly two availability zones."
  }
}
