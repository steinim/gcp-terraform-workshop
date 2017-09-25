# gcp-terraform-workshop
Introduction to provisioning basic infrastructure on Google Cloud Platform with Terraform.

In this tutorial you will learn how to use Terrafrom for provisioning basic infrastructure on the Google Cloud Platform (GCP), including projects, Identity and Access Management (IAM) policies, networking and deployemnt of a demo application on Container Engine.

## Before you begin
1. This tutorial assumes you already have a Cloud Platform account set up for your organization and that you are allowed to make organizational-level changes in the account.
2. This tutorial assumes that you have the following tools installed.
    * Terraform (`brew install terrafrom`)
    * Google Cloud SDK gcloud command-line tool (brew install gcloud`)

### Costs
This tutorial uses billable components of GCP, Google Cloud Storage and Compute Engine.

## Objectives

* Create a Terraform Admin Project for the service account and remote state bucket.
* Grant Organization-level permissions to the service account.
* Configure remote state in Google Cloud Storage (GCS).
* Use Terraform to provision a new project and an instance in that project.
* Architecture diagram for tutorial components:

Figure 1. Architecture diagram for tutorial components architecture diagram

# Set up the environment
The setup is based on [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) by [Dan Isla](https://github.com/danisla), Google Cloud Solution Architect, Google

## Export the following variables to your environment for use throughout the tutorial.

```
export TF_VAR_org_id=YOUR_ORG_ID
export TF_VAR_billing_account=YOUR_BILLING_ACCOUNT_ID
export TF_ADMIN=${USER}-terraform-admin
export TF_CREDS=~/.config/gcloud/terraform-admin.json
```

Note: The TF_ADMIN variable will be used for the name of the Terraform Admin Project and must be unique.

You can find the values for YOUR_ORG_ID and YOUR_BILLING_ACCOUNT_ID using the following commands:
```
gcloud beta organizations list
gcloud alpha billing accounts list
```

## Create the Terraform Admin Project

Using an Admin Project for your Terraform service account keeps the resources needed for managing your projects separate from the actual projects you create. While these resources could be created with Terraform using a service account from an existing project, in this tutorial you will create a separate project and service account exclusively for Terraform.

## Create a new project and link it to your billing account:
```
gcloud projects create ${TF_ADMIN} \
  --organization ${TF_VAR_org_id} \
  --set-as-default

gcloud alpha billing accounts projects link ${TF_ADMIN} \
  --account-id ${TF_VAR_billing_account}
Create the Terraform service account

Create the service account in the Terraform admin project and download the JSON credentials:

gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"

gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com
Grant the service account permission to view the Admin Project and manage Cloud Storage:

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

### Add organization/folder-level permissions

Grant the service account permission to create projects and assign billing accounts:

```
gcloud beta organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectCreator

gcloud beta organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/billing.user
```

## Set up remote state in Cloud Storage

Create the remote backend bucket in Cloud Storage and the backend.tf file for storage of the terraform.tfstate file:

```
gsutil mb -p ${TF_ADMIN} gs://${TF_ADMIN}

cat > backend.tf <<EOF
terraform {
 backend "gcs" {
   bucket = "${TF_ADMIN}"
   path   = "/"
 }
}
EOF
```

Next, initialize the backend:

`terraform init`

```Use Terraform to create a new project and Compute Engine instance

The project.tf file:
```
variable "project_name" {}
variable "billing_account" {}
variable "org_id" {}
variable "region" {}

provider "google" {
 region = "${var.region}"
}

resource "random_id" "id" {
 byte_length = 4
 prefix      = "${var.project_name}-"
}

resource "google_project" "project" {
 name            = "${var.project_name}"
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

output "project_id" {
 value = "${google_project.project.project_id}"
}
```
