variable "name" {}
variable "project" {}
variable "region" {}
variable "zones" { type = "list" }
variable "cidr" {}
variable "public_subnets" { type = "list" }
variable "private_subnets" { type = "list" }
variable "bastion_image" {}
variable "bastion_instance_type" {}
variable "user" {}
variable "ssh_key" {}
variable "db_ip" {}
