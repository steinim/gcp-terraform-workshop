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
}

module "mysql-db" {
  source           = "../modules/db"
  db_name          = "${module.project.name}"
  project          = "${module.project.id}"
  region           = "${var.region}"
  db_name          = "${module.project.name}"
  user_name        = "hello"
  user_password    = "hello"
}

module "instance-template" {
  source        = "../modules/instance-template"
  name          = "${module.project.name}"
  env           = "${var.env}"
  project       = "${module.project.id}"
  region        = "${var.region}"
  network_name  = "${module.network.name}"
  image         = "${var.app_image}"
  instance_type = "${var.app_instance_type}"
  user          = "${var.user}"
  ssh_key       = "${var.ssh_key}"
  db_name       = "${module.project.name}"
  db_user       = "hello"
  db_password   = "hello"
  db_ip         = "${module.mysql-db.instance_address}"
}

module "lb" {
  source            = "../modules/lb"
  name              = "${module.project.name}"
  project           = "${module.project.id}"
  region            = "${var.region}"
  count             = "${var.appserver_count}"
  instance_template = "${module.instance-template.instance_template}"
  zones             = "${var.zones}"
}
