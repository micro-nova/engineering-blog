resource "google_certificate_manager_certificate" "default" {
  name = "${var.project}-${var.dns_name}-${var.env}"
  managed {
    domains = [
      google_certificate_manager_dns_authorization.default.domain,
    ]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.default.id,
    ]
  }
}

resource "google_certificate_manager_dns_authorization" "default" {
  name        = "${var.project}-${var.dns_name}-${var.env}"
  description = "The default dnss"
  domain      = "${var.dns_name}.${var.dns_zone_name}"
}

resource "google_certificate_manager_certificate_map" "certificate_map" {
  name = "${var.project}-${var.dns_name}-${var.env}"
}

resource "google_certificate_manager_certificate_map_entry" "default" {
  name         = "${var.project}-${var.dns_name}-${var.env}"
  map          = google_certificate_manager_certificate_map.certificate_map.name
  certificates = [google_certificate_manager_certificate.default.id]
  matcher      = "PRIMARY"
}

resource "cloudflare_record" "cert_record" {
  zone_id = data.cloudflare_zone.zone.id
  name    = google_certificate_manager_dns_authorization.default.dns_resource_record[0].name
  type    = google_certificate_manager_dns_authorization.default.dns_resource_record[0].type
  value   = google_certificate_manager_dns_authorization.default.dns_resource_record[0].data
  ttl     = 600
}
