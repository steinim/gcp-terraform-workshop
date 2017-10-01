resource "google_compute_instance" "bastion" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, 0)}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    subnetwork = "${element(var.public_subnet_names, 0)}"

    access_config {
      # ephemeral
    }
  }

  tags = ["bastion"]
}