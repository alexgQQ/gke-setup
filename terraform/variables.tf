variable "gke_project" {
  default     = ""
  description = "GCP project to create resources in"
}

variable "gke_zone" {
  default     = ""
  description = "The GCP zone for resources"
}

variable "gke_region" {
  default     = ""
  description = "The GCP region for resources"
}

variable "cloudflare_api_token" {
  default     = ""
  description = "Api token with cloudflare zone access"
}

variable "cloudflare_zone_id" {
  default     = ""
  description = "The id of your cloudflare zone"
}

variable "cloudflare_domain" {
  default     = ""
  description = "The domain name of your cloudflare zone"
}

variable "gke_node_port" {
  default     = 30000
  description = "The exposed node port on GKE"
}
