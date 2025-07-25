resource "google_compute_global_address" "address" {
  name = "${var.project}-${var.dns_name}-${var.env}-lb"
}

resource "google_compute_backend_bucket" "backend_bucket" {
  name        = "${var.project}-${var.dns_name}-${var.env}" # the regex for this is restrictive
  bucket_name = "${var.dns_name}.${var.dns_zone_name}"
  enable_cdn  = true
}

resource "google_compute_target_https_proxy" "lb" {
  name            = "${var.project}-${var.dns_name}-${var.env}" # the regex for this is restrictive
  url_map         = google_compute_url_map.map.id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.certificate_map.id}"
}

resource "google_compute_url_map" "map" {
  name = "${var.project}-${var.dns_name}-${var.env}" # the regex for this is restrictive

  default_service = google_compute_backend_bucket.backend_bucket.self_link
}

resource "google_compute_global_forwarding_rule" "rule" {
  name                  = "${var.project}-${var.dns_name}-${var.env}"
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_protocol           = "TCP"
  target                = google_compute_target_https_proxy.lb.id
  ip_address            = google_compute_global_address.address.address
}

## It sure would be nice if it didn't require a full new LB to redirect from http to https.
resource "google_compute_url_map" "http_redirect" {
  name = "${var.project}-${var.dns_name}-${var.env}-redirect"

  default_url_redirect {
    strip_query    = false
    https_redirect = true // this is the magic
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "${var.project}-${var.dns_name}-${var.env}-redirect"
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name       = "${var.project}-${var.dns_name}-${var.env}-redirect"
  target     = google_compute_target_http_proxy.http_redirect.self_link
  ip_address = google_compute_global_address.address.address
  port_range = "80"
}
