variable "billing_account" {}
variable "org_id" {}
variable "region" { default = "europe-west1" }
variable "env" { default = "prod" }
variable "zones" { default = ["europe-west1-b", "europe-west1-c"] }
variable "cidr" { default = "10.0.0.0/16"}
variable "private_subnets" { default = ["10.0.1.0/24", "10.0.2.0/24"] }
variable "public_subnets" { default = ["10.0.3.0/24", "10.0.4.0/24"] }
variable "bastion_image" { default = "centos-7-v20170918" }
variable "bastion_instance_type" { default = "f1-micro" }
variable "user" {}
variable "ssh_key" {}

