output "private_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.address}"
}
output "public_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}"
}
