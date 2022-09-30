resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  value   = google_compute_address.ip_addresses[0].address
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "www_api" {
  zone_id = var.cloudflare_zone_id
  name    = "www.api"
  value   = google_compute_address.ip_addresses[0].address
  type    = "A"
  proxied = true
}

resource "cloudflare_ruleset" "http_origin_example" {
  zone_id     = var.cloudflare_zone_id
  name        = "GKE Node Port Rewrite"
  description = "Rewrite http traffic to the node port available on GKE"
  kind        = "zone"
  phase       = "http_request_origin"

  rules {
    action = "route"
    action_parameters {
      origin {
        port = var.gke_node_port
      }
    }
    expression  = "(http.host eq \"api.${var.cloudflare_domain}\")"
    description = "Rewrite api traffic"
    enabled     = true
  }
}
