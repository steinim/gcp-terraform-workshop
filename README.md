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

### Costs
Google Cloud Storage, Compute Engine and Cloud SQL are billable components.

## Architecture diagram for tutorial components:

![Architecture](https://github.com/steinim/gcp-terraform-workshop/raw/master/img/architecture.png)

# Task 1: Set up the environment
The setup is based on [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) by [Dan Isla](https://github.com/danisla), Google Cloud Solution Architect, Google

## Objectives
* Create a Terraform Admin Project for the service account and a remote state bucket.
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
cd terrafrom/test

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
Terraform resources used:
  * [provider "google"](https://www.terraform.io/docs/providers/google/index.html): The Google cloud provider config. The credentials will be pulled from the GOOGLE_CREDENTIALS environment variable (set later in tutorial).
  * [resource "random_id"](https://www.terraform.io/docs/providers/random/r/id.html): Project IDs must be unique. Generate a random one prefixed by the desired project ID.
  * [resource "google_project"](https://www.terraform.io/docs/providers/google/r/google_project.html): The new project to create, bound to the desired organization ID and billing account.
  * [resource "google_project_services"](https://www.terraform.io/docs/providers/google/r/google_project_services.html): Services and APIs enabled within the new project. Note that if you visit the web console after running Terraform, additional APIs may be implicitly enabled and Terraform would become out of sync. Re-running terraform plan will show you these changes before Terraform attempts to disable the APIs that were implicitly enabled. You can also set the full set of expected APIs beforehand to avoid the synchronization issue.

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

SSH into the bastion host:
`ssh -i ~/.ssh/<private_key> $USER@<public_ip>`

# Task 4: Instance templates

`git checkout task4`

SSH into the bastion host with ssh-agent forwarding and ssh to a webserver in the private network:
```
ssh -A -i ~/.ssh/<private_key> $USER@<public_ip>
ssh <instance_private_ip
```

Browse to the public ip's of the webservers.

# Task 5: Auto scaling and load balancing

`git checkout task5`

Browse to the public ip of the load balancer.

# (Task 6: Java application and reverse proxy)

You're on your own!

# (Task 7: Database)

You're on your own!

# Cleaning up

First, destroy the resources created by Terraform:
`terraform destroy`

Finally, delete the Terraform Admin project and all of its resources:
`gcloud projects delete ${TF_ADMIN}`

