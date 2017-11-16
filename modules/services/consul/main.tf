

data "triton_image" "consul" {
  name = "centos-7"
  type = "lx-dataset"
  most_recent = true
}


data "template_file" "user_data" {
  template = "${file("${path.module}/user-script.sh")}"

  vars {
    CONSUL_DOMAIN_NAME = "${var.domain_name}"
    CONSUL_EXPECTED = "${var.expect}"
    CONSUL_DATACENTER = "${var.data_center}"
  }
}

resource "triton_machine" "consul" {
  name = "${var.name}-${count.index}"

  package = "${var.package}"
  image = "${data.triton_image.consul.id}"

  count = "${var.instances}"
  
  cns {
    services = [ "${var.name}" ]
  }
  
  tags = {
    role = "consul"
  }

  networks = [
    "${var.networks}"
  ]

  connection {
    type = "ssh"
    user = "root"
    private_key = "${file(pathexpand("~/.ssh/id_rsa"))}"
    host = "${self.primaryip}"
    
    bastion_host = "${var.bastion_host}"
    bastion_user = "${var.bastion_user}"
  }

  # provisioner "file" {
  #   source = "${path.module}/tmux.conf"
  #   destination = "/root/.tmux.conf"
  # }
  # 
  # provisioner "file" {
  #   source = "${path.module}/screenrc"
  #   destination = "/root/.screenrc"
  # }
  
  provisioner "file" {
    source = "${path.module}/consul-genconfig.sh"
    destination = "/var/local/consul-genconfig.sh"
  }
  
  provisioner "file" {
    source = "${path.module}/consul-launcher.sh"
    destination = "/var/local/consul-launcher.sh"
  }
  
  provisioner "file" {
    source = "${path.module}/consul-reconfig.sh"
    destination = "/var/local/consul-reconfig.sh"
  }
  
  provisioner "remote-exec" {
    inline = "${data.template_file.user_data.rendered}"
  }
  
}


output "name" {
  value = "${triton_machine.consul.name}"
}

output "ips" {
  value = "${triton_machine.consul.*.primaryip}"
}
