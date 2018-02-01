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
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 90

    cpu_utilization {
      target = 0.8
    }
  }
}
