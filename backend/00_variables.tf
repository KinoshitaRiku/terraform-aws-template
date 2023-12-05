variable "project" {
  type        = string
  default     = "tf-template"
  description = "Project Name"
}

variable "env" {
  type        = string
  default     = "dev"
  description = "Environment"
}

variable "vpc_cidr" {
  type        = string
  default     = "192.168.0.0/16"
  description = "VPC Cidr"
}

variable "cidr_block_map" {
  type = map(string)
  default = {
    public_1a  = "192.168.1.0/24"
    public_1c  = "192.168.2.0/24"
    private_1a = "192.168.3.0/24"
    private_1c = "192.168.4.0/24"
  }
  description = "Domain"
}

#-----------------------------#
# database settings
#-----------------------------#
variable "db_password" {
  type        = string
  description = "DB Password"
}

variable "db_username" {
  type        = string
  description = "DB Username"
}

