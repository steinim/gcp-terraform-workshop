output "subnet_names" {
  value = ["${google_compute_subnetwork.private.*.name}"]
}
