output "name" {
  value = "${google_compute_network.network.name}"
}
output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}
output "gateway_ipv4"  {
  value = "${google_compute_network.network.gateway_ipv4}"
}
