variable "env" { default = "test" }
variable "region" { default = "europe-west3" }
variable "billing_account" {}
variable "org_id" {}
variable "zones" { default = ["europe-west3-a", "europe-west3-b"] }
variable "cidr" { default = "192.168.0.0/16"}
variable "private_subnets" { default = ["192.168.1.0/24", "192.168.2.0/24"] }
variable "public_subnets" { default = ["192.168.100.0/24", "192.168.200.0/24"] }
variable "bastion_image" { default = "centos-7-v20170918" }
variable "bastion_instance_type" { default = "f1-micro" }
variable "appserver_count" { default = 2 }
variable "app_image" { default = "centos-7-v20170918" }
variable "app_instance_type" { default = "f1-micro" }
variable "user" {}
variable "ssh_key" {}
