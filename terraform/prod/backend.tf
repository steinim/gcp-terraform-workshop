terraform {
  backend "gcs" {
    bucket  = "tf-state"
    prefix  = "terraform/prod-state"
  }
}
