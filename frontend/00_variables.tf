variable "project" {
  type        = string
  default     = "terraform-aws-template"
  description = "Project Name"
}

variable "env" {
  type        = string
  default     = "dev"
  description = "Environment"
}

variable "domain" {
  type        = string
  default     = "test.com"
  description = "Domain"
}

variable "ip_whitelist" {
  type        = list(string)
  default     = [
    "1.1.1.1/32",
    "2.2.2.2/32"
  ]
  description = "Domain"
}
