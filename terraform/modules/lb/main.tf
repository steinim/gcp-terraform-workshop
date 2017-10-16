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
  name        = "${var.name}-backend"
  project     = "${var.project}"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  enable_cdn  = false

  #backend {
  #  group = "${google_compute_instance_group_manager.webservers.instance_group}"
  #}

  health_checks = ["${google_compute_http_health_check.healthcheck.self_link}"]
}

resource "google_compute_http_health_check" "healthcheck" {
  name                = "${var.name}-healthcheck"
  project             = "${var.project}"
  port                = 80
  request_path        = "/"
  check_interval_sec  = 1
  timeout_sec         = 1
}

resource "google_compute_instance_group" "webservers" {
  name      = "${var.name}-webservers-instance-group-${count.index}"
  project   = "${var.project}"
  count     = "${var.count}"
  instances = [ "${element(var.instances, count.index)}" ]

  named_port {
    name = "http"
    port = "80"
  }

  zone = "${element(var.zones, count.index)}"
}
