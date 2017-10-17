# gcp-terraform-workshop
Introduction to provisioning basic infrastructure on Google Cloud Platform with Terraform.

In this tutorial you will learn how to use Terraform for provisioning basic infrastructure on the Google Cloud Platform (GCP), including projects, networking and deployment of webservers on Compute Engine in an autoscaled and load balanced environment. Further work includes setting up a Cloud SQL database and deployment of a Java application with a reverse proxy in front.

## Before you begin
1. This tutorial assumes you already have a Cloud Platform account set up for your organization and that you are allowed to make organizational-level changes in the account.
2. Install Google Cloud SDK and Terraform.
  ```
  brew update
  brew install Caskroom/cask/google-cloud-sdk
  brew install terraform
  ```
3. Fork this repo
4. Check out the `start` branch: `git checkout start`
5. Open [the Terraform doc for GCP](https://www.terraform.io/docs/providers/google/)

### Costs
Google Cloud Storage, Compute Engine and Cloud SQL are billable components.

## Architecture diagram for tutorial components:

![Architecture](https://github.com/steinim/gcp-terraform-workshop/raw/master/img/architecture.png)

# Task 1: Set up the environment
The setup is based on [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) by [Dan Isla](https://github.com/danisla), Google Cloud Solution Architect, Google

## Objectives
* Create a Terraform admin project for the service account and a remote state bucket.
* Configure remote state in Google Cloud Storage (GCS).

## Export the following variables to your environment for use throughout the tutorial.

Tip! Put the exports in `~/.gcp_env` and place `. ~/.gcp_env` in your `~/.bashrc`

```
export GOOGLE_REGION=europe-west3 # change this if you want to use a different region
export TF_VAR_org_id=<your_org_id>
export TF_VAR_billing_account=<your_billing_account_id>
export TF_VAR_region=${GOOGLE_REGION}
export TF_VAR_user=${USER}
export TF_VAR_ssh_key=<path_to_your_public_ssh_key>
export TF_ADMIN=${USER}-terraform-admin
export TF_CREDS=~/.config/gcloud/terraform-admin.json
```

**Note:** The TF_ADMIN variable will be used for the name of the Terraform Admin Project and must be unique.

You can find the values for <your_org_id> and <your_billing_account_id> using the following commands:
```
gcloud beta organizations list
gcloud alpha billing accounts list
```

## Create the Terraform Admin Project

Using an Admin Project for your Terraform service account keeps the resources needed for managing your projects separate from the actual projects you create. While these resources could be created with Terraform using a service account from an existing project, in this tutorial you will create a separate project and service account exclusively for Terraform.

Create a new project and link it to your billing account:
```
gcloud projects create ${TF_ADMIN} \
  --organization ${TF_VAR_org_id} \
  --set-as-default

gcloud alpha billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}
```

## Create the Terraform service account

Create the service account in the Terraform admin project and download the JSON credentials:
```
gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"

gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com
```

Grant the service account permission to view the Admin Project and manage Cloud Storage:
```
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/storage.admin
```

Any actions that Terraform performs require that the API be enabled to do so. In this guide, Terraform requires the following:
```
gcloud service-management enable cloudresourcemanager.googleapis.com
gcloud service-management enable cloudbilling.googleapis.com
gcloud service-management enable iam.googleapis.com
gcloud service-management enable compute.googleapis.com
```

**NB!** Maybe you need to accept terms under [GCP Privacy & Security](https://console.cloud.google.com/iam-admin/privacy)

## Set up remote state in Cloud Storage

Create the remote backend bucket in Cloud Storage and the backend.tf file for storage of the terraform.tfstate file:
```
cd terraform/test

gsutil mb -l ${TF_VAR_region} -p ${TF_ADMIN} gs://${TF_ADMIN} # Ignore warning about AWS_CREDENTIAL_FILE

cat > backend.tf <<EOF
terraform {
 backend "gcs" {
   bucket = "${TF_ADMIN}"
   path   = "/"
 }
}
EOF
```

## Initialize the backend:
`terraform init` and check that everything works with `terraform plan`

# Task 2: Create a new project

## Objectives
* Organize your code into environments and modules
* Usage of variables and outputs
* Use Terraform to provision a new project

## Create your first module: `project`

Terraform resources used:
  * [provider "google"](https://www.terraform.io/docs/providers/google/index.html)
  * [resource "random_id"](https://www.terraform.io/docs/providers/random/r/id.html): Project IDs must be unique. Generate a random one prefixed by the desired project ID.
  * [resource "google_project"](https://www.terraform.io/docs/providers/google/r/google_project.html): The new project to create, bound to the desired organization ID and billing account.
  * [resource "google_project_services"](https://www.terraform.io/docs/providers/google/r/google_project_services.html): Services and APIs enabled within the new project.

Create the following files in `modules/project/`:
  * `main.tf`
  * `vars.tf`
  * `outputs.tf`

`main.tf`:
```
provider "google" {
 region = "${var.region}"
}

resource "random_id" "id" {
 byte_length = 4
 prefix      = "${var.name}-"
}

resource "google_project" "project" {
 name            = "${var.name}"
 project_id      = "${random_id.id.hex}"
 billing_account = "${var.billing_account}"
 org_id          = "${var.org_id}"
}

resource "google_project_services" "project" {
 project = "${google_project.project.project_id}"
 services = [
   "compute.googleapis.com"
 ]
}
```

`outputs.tf`:
```
output "id" {
 value = "${google_project.project.id}"
}

output "name" {
 value = "${google_project.project.name}"
}
```
Terraform resources used:
  * [output "id"](https://www.terraform.io/intro/getting-started/outputs.html): The project ID is randomly generated for uniqueness. Use an output variable to display it after Terraform runs for later reference. The length of the project ID should not exceed 30 characters.
  * [output "name"](https://www.terraform.io/intro/getting-started/outputs.html): The project name.

`vars.tf`:
```
variable "name" {}
variable "region" {}
variable "billing_account" {}
variable "org_id" {}
```

## Create your first environment: test

Create the following files in `test/`:
  * `main.tf`
  * `vars.tf`

`main.tf`:
```
module "project" {
  source          = "../modules/project"
  name            = "hello-${var.env}"
  region          = "${var.region}"
  billing_account = "${var.billing_account}"
  org_id          = "${var.org_id}"
}
```

`vars.tf`:
```
variable "env" { default = "test" }
variable "region" { default = "europe-west3" }
variable "billing_account" {}
variable "org_id" {}
```

## Initialize once again to download providers used in the module:
`terraform init`

## Always run plan first!
`terraform plan`

## Provision the infrastructure
`terraform apply`

Verify your success in the GCP console 💰

# Task 3: Networking and bastion host

`git checkout task3`

## Create the network module

```
modules/network/
├── vars.tf
├── main.tf
├── outputs.tf
├── bastion
│   ├── main.tf
│   ├── outputs.tf
│   └── vars.tf
├── subnet
│   ├── main.tf
│   ├── outputs.tf
│   └── vars.tf
```

<p>
<details>
<summary><strong>Subnet module</strong> `modules/network/subnet`</summary>

```
# main.tf
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}"
  project       = "${var.project}"
  region        = "${var.region}"
  network       = "${var.network}"
  ip_cidr_range = "${var.ip_range}"
}

---

# vars.tf
variable "name" {}
variable "project" {}
variable "region" {}
variable "network" {}
variable "ip_range" {}

---

# outputs.tf
output "name" {
  value = "${google_compute_subnetwork.subnet.name}"
}
output "ip_range" {
  value = "${google_compute_subnetwork.subnet.ip_cidr_range}"
}

```
</details>
</p>

<p>
<details>
<summary><strong>Bastion host module</strong>`modules/network/bastion`</summary>

```
# main.tf
resource "google_compute_instance" "bastion" {
  name         = "${var.name}"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  zone         = "${element(var.zones, 0)}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    subnetwork = "${var.subnet_name}"

    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  tags = ["bastion"]
}

---

# vars.tf
variable "name" {}
variable "project" {}
variable "zones" { type = "list" }
variable "subnet_name" {}
variable "image" {}
variable "instance_type" {}
variable "user" {}
variable "ssh_key" {}

---

# outputs.tf
output "private_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.address}"
}
output "public_ip" {
  value = "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}"
}
```
</details>
</p>

<p>
<details>
<summary><strong>Network</strong>`modules/network/`</summary>

```
# main.tf
resource "google_compute_network" "network" {
  name    = "${var.name}-network"
  project = "${var.project}"
}

resource "google_compute_firewall" "allow-internal" {
  name    = "${var.name}-allow-internal"
  project = "${var.project}"
  network = "${var.name}-network"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [
    "${module.management_subnet.ip_range}",
    "${module.webservers_subnet.ip_range}"
  ]
}

resource "google_compute_firewall" "allow-ssh-from-everywhere-to-bastion" {
  name    = "${var.name}-allow-ssh-from-everywhere-to-bastion"
  project = "${var.project}"
  network = "${var.name}-network"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["bastion"]
}

resource "google_compute_firewall" "allow-ssh-from-bastion-to-webservers" {
  name               = "${var.name}-allow-ssh-from-bastion-to-webservers"
  project            = "${var.project}"
  network            = "${var.name}-network"
  direction          = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags        = ["http"]
}

resource "google_compute_firewall" "allow-ssh-to-webservers-from-bastion" {
  name          = "${var.name}-allow-ssh-to-private-network-from-bastion"
  project       = "${var.project}"
  network       = "${var.name}-network"
  direction     = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags   = ["bastion"]
}

resource "google_compute_firewall" "allow-http-to-appservers" {
  name          = "${var.name}-allow-http-to-appservers"
  project       = "${var.project}"
  network       = "${var.name}-network"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]

  source_tags   = ["http"]
}

module "management_subnet" {
  source   = "./subnet"
  project  = "${var.project}"
  region   = "${var.region}"
  name     = "${var.management_subnet_name}"
  network  = "${google_compute_network.network.self_link}"
  ip_range = "${var.management_subnet_ip_range}"
}

module "webservers_subnet" {
  source   = "./subnet"
  project  = "${var.project}"
  region   = "${var.region}"
  name     = "${var.webservers_subnet_name}"
  network  = "${google_compute_network.network.self_link}"
  ip_range = "${var.webservers_subnet_ip_range}"
}

module "bastion" {
  source        = "./bastion"
  name          = "${var.name}-bastion"
  project       = "${var.project}"
  zones         = "${var.zones}"
  subnet_name   = "${module.management_subnet.name}"
  image         = "${var.bastion_image}"
  instance_type = "${var.bastion_instance_type}"
  user          = "${var.user}"
  ssh_key       = "${var.ssh_key}"
}

---

# vars.tf
variable "name" {}
variable "project" {}
variable "region" {}
variable "zones" { type = "list" }
variable "webservers_subnet_name" {}
variable "webservers_subnet_ip_range" {}
variable "management_subnet_name" {}
variable "management_subnet_ip_range" {}
variable "bastion_image" {}
variable "bastion_instance_type" {}
variable "user" {}
variable "ssh_key" {}

---

# outputs.tf
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
```
</details>
</p>

<p>
<details>
<summary><strong>Use the subnet module in your main project</strong> `test/`</summary>

```
# main.tf

...

module "network" {
  source                     = "../modules/network"
  name                       = "${module.project.name}"
  project                    = "${module.project.id}"
  region                     = "${var.region}"
  zones                      = "${var.zones}"
  webservers_subnet_name     = "webservers"
  webservers_subnet_ip_range = "${var.webservers_subnet_ip_range}"
  management_subnet_name     = "management"
  management_subnet_ip_range = "${var.management_subnet_ip_range}"
  bastion_image              = "${var.bastion_image}"
  bastion_instance_type      = "${var.bastion_instance_type}"
  user                       = "${var.user}"
  ssh_key                    = "${var.ssh_key}"
}

---

# vars.tf
...
variable "zones" { default = ["europe-west3-a", "europe-west3-b"] }
variable "webservers_subnet_ip_range" { default = "192.168.1.0/24"}
variable "management_subnet_ip_range" { default = "192.168.100.0/24"}
variable "bastion_image" { default = "centos-7-v20170918" }
variable "bastion_instance_type" { default = "f1-micro" }
variable "user" {}
variable "ssh_key" {}

```

</details>
</p>

## Init, plan, apply!
```
terraform init
terraform plan
terraform apply
```

## SSH into the bastion host 💰
`ssh -i ~/.ssh/<private_key> $USER@<public_ip>`

# Task 4: Instance templates

`git checkout task4`

## Create the instance template module

```
modules/instance-template
├── main.tf
├── outputs.tf
└── vars.tf
```

<p>
<details>
<summary><strong>Instance template module</strong> `modules/instance-template/`</summary>

```
# main.tf

resource "google_compute_instance_template" "webserver" {
  name         = "${var.name}-webserver-instance-template"
  project      = "${var.project}"
  machine_type = "${var.instance_type}"
  region       = "${var.region}"

  metadata {
    ssh-keys = "${var.user}:${file("${var.ssh_key}")}"
  }

  disk {
    source_image = "${var.image}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork         = "${var.subnet_name}"
    subnetwork_project = "${var.project}"
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  metadata_startup_script = "yum install -y nginx ; service nginx start ; hostname > /usr/share/nginx/html/index.html"

  tags = ["http"]

  labels = {
    environment = "${var.env}"
  }
}

---

# vars.tf

variable "name" {}
variable "project" {}
variable "subnet_name" {}
variable "image" {}
variable "instance_type" {}
variable "user" {}
variable "ssh_key" {}
variable "env" {}
variable "region" {}

---

# outputs.tf

output "instance_template" {
  value = "${google_compute_instance_template.webserver.self_link}"
}

```

</details>
</p>

<p>
<details>
<summary><strong>Use the instance template module in your main project</strong> `test/`</summary>

```
# main.tf

...

module "instance-template" {
  source        = "../modules/instance-template"
  name          = "${module.project.name}"
  env           = "${var.env}"
  project       = "${module.project.id}"
  region        = "${var.region}"
  subnet_name   = "${module.network.management_subnet_name}"
  image         = "${var.app_image}"
  instance_type = "${var.app_instance_type}"
  user          = "${var.user}"
  ssh_key       = "${var.ssh_key}"
}

---

# vars.tf

...

variable "appserver_count" { default = 2 }
variable "app_image" { default = "centos-7-v20170918" }
variable "app_instance_type" { default = "f1-micro" }

```

</details>
</p>

## Init, plan, apply!
```
terraform init
terraform plan
terraform apply
```

## Check that your instance template is created in the console 💰

Browse to the public ip's of the webservers.

# Task 5: Auto scaling and load balancing

`git checkout task5`

What you'll need 😰:

  * google_compute_global_forwarding_rule
  * google_compute_target_http_proxy
  * google_compute_url_map
  * google_compute_backend_service
  * google_compute_http_health_check
  * google_compute_instance_group_manager
  * google_compute_target_pool
  * google_compute_instance_group
  * google_compute_autoscaler

## Create th lb module

```
modules/lb
├── main.tf
└── vars.tf
```

<p>
<details>
<summary><strong>Load balancer module</strong> `modules/lb/`</summary>

```

# main.tf
resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "${var.name}-global-forwarding-rule"
  project    = "${var.project}"
  target     = "${google_compute_target_http_proxy.target_http_proxy.self_link}"
  port_range = "80"
}

resource "google_compute_target_http_proxy" "target_http_proxy" {
  name        = "${var.name}-proxy"
  project     = "${var.project}"
  url_map     = "${google_compute_url_map.url_map.self_link}"
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.name}-url-map"
  project         = "${var.project}"
  default_service = "${google_compute_backend_service.backend_service.self_link}"
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.name}-backend-service"
  project               = "${var.project}"
  port_name             = "http"
  protocol              = "HTTP"
  backend {
    group                 = "${element(google_compute_instance_group_manager.webservers.*.instance_group, 0)}"
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }

  backend {
    group                 = "${element(google_compute_instance_group_manager.webservers.*.instance_group, 1)}"
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }

  health_checks = ["${google_compute_http_health_check.healthcheck.self_link}"]
}

resource "google_compute_http_health_check" "healthcheck" {
  name         = "${var.name}-healthcheck"
  project      = "${var.project}"
  port         = 80
  request_path = "/"
}

resource "google_compute_instance_group_manager" "webservers" {
  name               = "${var.name}-instance-group-manager-${count.index}"
  project            = "${var.project}"
  instance_template  = "${var.instance_template}"
  base_instance_name = "${var.name}-webserver-instance"
  count              = "${var.count}"
  zone               = "${element(var.zones, count.index)}"
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name    = "${var.name}-scaler-${count.index}"
  project = "${var.project}"
  count   = "${var.count}"
  zone    = "${element(var.zones, count.index)}"
  target  = "${element(google_compute_instance_group_manager.webservers.*.self_link, count.index)}"

  autoscaling_policy = {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

---

# vars.tf

variable "name" {}
variable "project" {}
variable "region" {}
variable "count" {}
variable "instance_template" {}
variable "zones" { type = "list" }


```
</details>
</p>

<p>
<details>
<summary><strong>Use the load balancer module in your main project</strong> `test/`</summary>

```

# main.tf

...

module "lb" {
  source            = "../modules/lb"
  name              = "${module.project.name}"
  project           = "${module.project.id}"
  region            = "${var.region}"
  count             = "${var.appserver_count}"
  instance_template = "${module.instance-template.instance_template}"
  zones             = "${var.zones}"
}

```

</details>
</p>

## Init, plan, apply!
```
terraform init
terraform plan
terraform apply
```

## SSH into the bastion host with ssh-agent forwarding and ssh to a webserver in the private network 💰
```
ssh -A -i ~/.ssh/<private_key> $USER@<public_ip>
ssh <instance_private_ip
```

## Browse to the public ip of the load balancer 💰

💰💰💰


# (Task 6: Java application and reverse proxy)

`git checkout task6`

You're on your own!

# (Task 7: Database)

You're on your own!

# Cleaning up

First, destroy the resources created by Terraform:
`terraform destroy --force`

Finally, delete the Terraform Admin project and all of its resources:
`gcloud projects delete ${TF_ADMIN}`

