output "ip_range" {
  value = "${google_compute_subnetwork.subnet.ip_cidr_range}"
}
output "self_link" {
  value = "${google_compute_subnetwork.subnet.self_link}"
}
