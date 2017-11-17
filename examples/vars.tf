variable "triton_region" {
  type = "string"
  description = "Triton region name (name of the Triton profile like us-west-1 will do)"
}

variable "triton_account_name" {
  type = "string"
  description = "Triton account name"
}

variable "triton_account_uuid" {
  type = "string"
  description = "Triton account uuid (can be obtained by running 'triton account get')"
}

variable "triton_url" {
  type = "string"
  description = "Triton endpoint URL (can be obtained by running 'triton profile get')"
}

variable "bastion_host" {
  type = "string"
  default = ""
  description = "IP address of Bastion host if consul instances do not have public IP addresses"
}

variable "consul_name" {
  type = "string"
  description = "Basename of the Triton instances for Consul, also used for CNS name prefix"
}
