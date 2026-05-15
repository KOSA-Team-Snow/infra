variable "region" {
  type        = string
  default     = "ap-northeast-2"
  description = "AWS region for the DR environment."
}

variable "dr_active" {
  type        = bool
  default     = false
  description = "When true, expand DR-only network resources such as the second NAT Gateway."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "CIDR block for the AWS DR VPC."
}

variable "azs" {
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
  description = "Availability zones used by the DR network."

  validation {
    condition     = length(var.azs) == 2
    error_message = "This Phase 1 network module expects exactly two availability zones."
  }
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags applied to all supported AWS resources."
  default = {
    Project     = "kosa-project-team3"
    Environment = "dr"
    ManagedBy   = "terraform"
  }
}
