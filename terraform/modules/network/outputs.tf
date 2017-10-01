output "name" {
  value = "${google_compute_network.network.name}"
}

output "public_subnet_names" {
  value = "${module.public_subnet.subnet_names}"
}

output "private_subnet_names" {
  value = "${module.private_subnet.subnet_names}"
}

output "bastion_public_ip" {
  value = "${module.bastion.public_ip}"
}

output "gateway_ipv4"  {
  value = "${google_compute_network.network.gateway_ipv4}"
}
