output "instance_template" {
  value = "${google_compute_instance_template.webserver.self_link}"
}
