resource "google_compute_subnetwork" "private" {
  name          = "${var.name}-${count.index}"
  project       = "${var.project}"
  count         = "${length(var.cidrs)}"
  ip_cidr_range = "${element(var.cidrs, count.index)}"
  network       = "${var.network}"
  region        = "${var.region}"
}
