
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
    subnetwork         = "${var.subnet_name}"
    subnetwork_project = "${var.project}"
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  metadata_startup_script = "yum install -y nginx ; service nginx start ; hostname > /usr/share/nginx/html/index.html"

  tags = ["http"]

  labels = {
    environment = "${var.env}"
  }
}
