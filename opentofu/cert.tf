resource "google_certificate_manager_certificate" "default" {
  name = "${var.dns_name}-${var.env}" # the regex for this resource is restrictive
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
  name        = "${var.dns_name}-${var.env}" # the regex for this resource is restrictive
  description = "The default dnss"
  domain      = "${var.dns_name}.${var.dns_zone_name}"
}

resource "google_certificate_manager_certificate_map" "certificate_map" {
  name = "${var.dns_name}-${var.env}" # the regex for this resource is restrictive
}

resource "google_certificate_manager_certificate_map_entry" "default" {
  name         = "${var.dns_name}-${var.env}" # the regex for this resource is restrictive
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
