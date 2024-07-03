data "cloudflare_zone" "zone" {
  name = var.dns_zone_name
}

resource "cloudflare_record" "record" {
  zone_id = data.cloudflare_zone.zone.id
  name    = var.dns_name
  value   = google_compute_global_forwarding_rule.rule.ip_address
  type    = "A"
  proxied = false
  ttl     = 600
}
