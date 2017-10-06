variable "env" { default = "test" }
variable "billing_account" {}
variable "org_id" {}
variable "region" {}
variable "zones" { default = ["europe-west3-a", "europe-west3-b"] }
variable "webservers_subnet_ip_range" { default = "192.168.1.0/24"}
variable "management_subnet_ip_range" { default = "192.168.100.0/24"}
variable "bastion_image" { default = "centos-7-v20170918" }
variable "bastion_instance_type" { default = "f1-micro" }
variable "appserver_count" { default = 2 }
variable "app_image" { default = "centos-7-v20170918" }
variable "app_instance_type" { default = "f1-micro" }
variable "user" {}
variable "ssh_key" {}
variable "db_region" { default = "europe-west1" }
variable "db_tier" { default = "db-f1-micro" }
