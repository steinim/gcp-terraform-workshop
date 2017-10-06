module "project" {
  source          = "../modules/project"
  name            = "hello-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
}

module "network" {
  source                     = "../modules/network"
  name                       = "${module.project.name}"
  project                    = "${module.project.id}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  webservers_subnet_name     = "webservers"
  webservers_subnet_ip_range = "${var.webservers_subnet_ip_range}"
  management_subnet_name     = "management"
 management_subnet_ip_range = "${var.management_subnet_ip_range}"
  bastion_image              = "${var.bastion_image}"
  bastion_instance_type      = "${var.bastion_instance_type}"
  user                       = "${var.user}"
  ssh_key                    = "${var.ssh_key}"
  #db_ip                      = "${module.db.ip}"
}

module "webserver" {
  source                = "../modules/compute"
  name                  = "${module.project.name}"
  project               = "${module.project.id}"
  count                 = "${var.appserver_count}"
  zones                 = "${var.zones}"
 subnet_name           = "${module.network.management_subnet_name}"
  image                 = "${var.app_image}"
  instance_type         = "${var.app_instance_type}"
 user                  = "${var.user}"
  ssh_key               = "${var.ssh_key}"
}

#module "db" {
#  source               = "../modules/db"
#  name                 = "${module.project.name}"
#  region               = "${var.db_region}"
#  zones                = "${var.zones}"
#  project              = "${module.project.id}"
#  host                 = "${module.network.gateway_ipv4}"
#  tier                 = "${var.db_tier}"
#}
