
resource "google_compute_instance_template" "webserver" {
  name         = "${var.name}-webserver-instance-template"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  region       = "${var.region}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  disk {
    source_image = "${var.image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network            = "${var.network_name}"
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  metadata_startup_script = "${file("${path.module}/scripts/startup.sh")}"

  tags = ["http"]

  labels = {
    environment = "${var.env}"
  }
}
