resource "google_compute_network" "network" {
  name    = "${var.name}-network"
  project = "${var.project}"
}

resource "google_compute_firewall" "allow-internal" {
  name    = "${var.name}-allow-internal"
  project = "${var.project}"
  network = "${var.name}-network"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    "${module.management_subnet.ip_range}",
    "${module.webservers_subnet.ip_range}"
  ]
}

resource "google_compute_firewall" "allow-ssh-from-everywhere-to-bastion" {
  name    = "${var.name}-allow-ssh-from-everywhere-to-bastion"
  project = "${var.project}"
  network = "${var.name}-network"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["bastion"]
}

resource "google_compute_firewall" "allow-ssh-from-bastion-to-webservers" {
  name               = "${var.name}-allow-ssh-from-bastion-to-webservers"
  project            = "${var.project}"
  network            = "${var.name}-network"
  direction          = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags        = ["ssh"]
}

resource "google_compute_firewall" "allow-ssh-to-webservers-from-bastion" {
  name          = "${var.name}-allow-ssh-to-private-network-from-bastion"
  project       = "${var.project}"
  network       = "${var.name}-network"
  direction     = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags   = ["bastion"]
}

resource "google_compute_firewall" "allow-http-to-appservers" {
  name          = "${var.name}-allow-http-to-appservers"
  project       = "${var.project}"
  network       = "${var.name}-network"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  source_tags   = ["http"]
}

resource "google_compute_firewall" "allow-db-connect-from-webservers" {
  name               = "${var.name}-allow-db-connect-from-webservers"
  project            = "${var.project}"
  network            = "${var.name}-network"
  direction          = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  destination_ranges = ["0.0.0.0/0"]

  target_tags        = ["db"]
}

module "management_subnet" {
  source   = "./subnet"
  project  = "${var.project}"
  region   = "${var.region}"
  name     = "${var.management_subnet_name}"
  network  = "${google_compute_network.network.self_link}"
  ip_range = "${var.management_subnet_ip_range}"
}

module "webservers_subnet" {
  source   = "./subnet"
  project  = "${var.project}"
  region   = "${var.region}"
  name     = "${var.webservers_subnet_name}"
  network  = "${google_compute_network.network.self_link}"
  ip_range = "${var.webservers_subnet_ip_range}"
}

module "bastion" {
  source        = "./bastion"
  name          = "${var.name}-bastion"
  project       = "${var.project}"
  zones         = "${var.zones}"
  subnet_name   = "${module.management_subnet.self_link}"
  image         = "${var.bastion_image}"
  instance_type = "${var.bastion_instance_type}"
  user          = "${var.user}"
  ssh_key       = "${var.ssh_key}"
}
