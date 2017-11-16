

variable "name" {
  type = "string"
  default = "consul"
}

variable "data_center" {
  type = "string"
}

variable "package" {
  type = "string"
  default = "g4-highcpu-1G"
}

variable "networks" {
  type = "list"
}

variable "instances" {
  type = "string"
}

variable "expect" {
  type = "string"
}

variable "bastion_host" {
  type = "string"
}

variable "bastion_user" {
  type = "string"
  default = "root"
}


variable "domain_name" {
  type = "string"
}
