
provider "triton" {
  account = "${var.triton_account_name}"
  url = "${var.triton_url}"
}

data "triton_network" "public" {
  name = "Joyent-SDC-Public"
}

data "triton_network" "fabric" {
  name = "My-Fabric-Network"
}

data "triton_network" "private" {
  name = "Joyent-SDC-Private"
}

module "consul" {
  source = "github.com/cinsk/terraform-triton-consul/modules/services/consul"

  name = "${var.consul_name}"
  networks = [
    "${data.triton_network.public.id}", # eth0
    "${data.triton_network.private.id}", # eth1
    "${data.triton_network.fabric.id}",  # eth2
  ]

  interface = "eth1"
  instances = 3
  expect = 3

  data_center = "${var.triton_region}"
  bastion_host = "${var.bastion_host}"
  
  # domain_name = "${var.consul_name}.svc.${var.triton_account_uuid}.${var.triton_region}.cns.joyent.com"
  domain_name = "${var.consul_name}.svc.${var.triton_account_uuid}.${var.triton_region}.triton.zone"
}

output "consul_name" {
  value = "${module.consul.name}"
}

output "consul_ips" {
  value = "${module.consul.ips}"
}
