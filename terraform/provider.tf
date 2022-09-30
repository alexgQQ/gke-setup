terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.38.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.38.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }

  required_version = ">= 0.14"
}

provider "google" {
  project = var.gke_project
  region  = var.gke_region
}

provider "google-beta" {
  project = var.gke_project
  region  = var.gke_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
