
# Consul Terraform Module

This package contains a [Terraform](https://www.terraform.io/) module to create a [Consul](https://www.consul.io) cluster in [Joyent Triton Cloud](https://www.joyent.com/).

## How to use this module

* `module/` contains the Terraform Consul module
* `example/` contains the example Terraform configuration to launch the Consul cluster.


1. `cd example/`
2. `cp terraform.tfvars.example terraform.tfvars`
3. Update `terraform.tfvars` to match your Triton environment.
   1. `triton_url` -- Run `triton profile get` and get the value of the field, "url".
   2. `triton_region` -- Run `triton profile get` and get the value of the field, "name".
   3. `triton_account_name` -- Run `triton profile get` and get the value of the field, "account".
   4. `triton_account_uuid` -- Run `triton account get` and get the value of the field, "id".
   5. `consul_name` -- This will become the prefix of the Triton instances of Consul cluster.  For example, if `consul_name` is "foo", then your instance names will be "foo-0", "foo-1", and so on.  Also, `examples/main.tf` will use this to generate proper Triton CNS name.

4. Update module variable in `main.tf`:
   1. `instances` -- number of Triton instances for the Consul cluster
   2. `expect` -- Consul will not start until the number of instances are equal or more than this value.
   3. `networks` -- Arrays of Triton network that Consul instances will join.  Note that Consul will refuse to start if the instance does not have a private IP.  The order of network matters! See below `interface` description.
   4. `interface` -- The NIC interface that Consul will advertise itself.   If you have more than one network in `networks`, you need to specify the interface name accordingly.  On LX brand zone, the first network in `networks` will be assigned to `eth0`, and so on.   On joyent(SmartOS) brand zone, the first network in `networks` will be assigned to `net0`.
   5. `bastion_host` -- Set the IP address of the Bastion server if `networks` does not have public network.
   6. `domain_name` -- CNS name for this Consul cluster.  This module relies on Triton CNS to discover initial Consul server participants.  This should matches the CNS domain name that Triton will generate for Consul instances.
   7. `private_key` -- Private key for the public key authentication for connecting instances.
   
   
5. Run `terraform get && terraform init && terraform plan` to see the execution plan.
6. Run `terraform apply` to deploy the Consul cluster.
7. Run `terraform destroy` if you want to delete the cluster.

## Inspection

On your Consul instances, these files are available for the inspections.

* `/usr/local/bin/consul` -- Consul binary
* `/var/local/consul.conf.json` -- the consul configuration file
* `/var/run/consul.pid` -- the pidfile of consul
* `/var/log/consul.log` -- the log file of consul

This module ran two helper scripts to launch the consul servers; (1) `consul-launcher.sh` and (2) `consul-reconfig.sh`.

`consul-launcher.sh` will start the Consul server and if the server failes, it will restart the consul server.  In the initial phase, it will wait until it detects enough number of Triton instances are ready, by looking at the number of CNS A records that you specified in `domain_name` and `expect` configuration value, and will launch the server.   Here are some files related to this script:

* `/var/local/consul-launcher.sh` -- this script itself.
* `/var/run/consul-launcher.pid` -- the pidfile of this process
* `/var/log/consul.launcher.log` -- the log file of this process

`consul-reconfig.sh` will check the CNS A records of the consul cluster periodically, and generate new consul configuration.  If the new configuration differs from the existing configuration, it will replace the configuration to the new one, and will notfiy the consul server by sending `SIGHUP` signal.  Also, if the number of A records are less than `expect` configuration value, it will do nothing.

* `/var/local/consul-reconfig.sh` -- this script itself.
* `/var/run/consul-reconfig.pid` -- the pidfile of this process
* `/var/log/consul.reconfig.log` -- the log file of this process
