output "name" {
  value = "${google_compute_network.network.name}"
}

output "management_subnet_name" {
  value = "${module.management_subnet.name}"
}

output "webservers_subnet_names" {
  value = "${module.management_subnet.name}"
}

output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}

output "gateway_ipv4"  {
  value = "${google_compute_network.network.gateway_ipv4}"
}
