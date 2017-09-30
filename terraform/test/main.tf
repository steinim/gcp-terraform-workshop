module "project" {
  source          = "../modules/project"
  name            = "hello-${var.env}"
  region          = "europe-west1"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
}

module "network" {
  source                = "../modules/network"
  name                  = "${module.project.name}"
  project               = "${module.project.id}"
  region                = "europe-west1"
  zones                 = "${var.zones}"
  cidr                  = "${var.cidr}"
  private_subnets       = "${var.private_subnets}"
  public_subnets        = "${var.public_subnets}"
  bastion_image         = "${var.bastion_image}"
  bastion_instance_type = "${var.bastion_instance_type}"
  user                  = "${var.user}"
  ssh_key               = "${var.ssh_key}"
}

