resource "google_compute_instance" "webserver" {

  count         = "${var.count}"

  name         = "${var.name}-webserver-${count.index}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, count.index)}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnet_name}"

    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  tags = ["http"]
}

