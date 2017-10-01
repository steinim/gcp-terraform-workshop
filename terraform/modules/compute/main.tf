resource "google_compute_instance" "app" {
  name         = "${var.name}-app-${count.index}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, count.index)}"
  count         = "${var.count}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    subnetwork = "${element(var.subnet_names, count.index)}"

    access_config {
      # ephemeral
    }
  }

  tags = ["${var.name}-app-${count.index}", "appserver"]
}
