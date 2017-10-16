output "instances" {
  value = ["${google_compute_instance.webserver.*.self_link}"]
}
