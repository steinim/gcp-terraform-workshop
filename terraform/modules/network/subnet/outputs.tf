output "name" {
  value = "${google_compute_subnetwork.subnet.name}"
}
output "ip_range" {
  value = "${google_compute_subnetwork.subnet.ip_cidr_range}"
}
