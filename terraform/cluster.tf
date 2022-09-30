resource "google_service_account" "gke_service_account" {
  account_id   = "gke-account"
  display_name = "The GKE service account"
}

resource "google_container_cluster" "primary_cluster" {
  name     = "primary-cluster"
  location = var.gke_zone

  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_node" {
  name       = "primary-node"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"
    disk_size_gb = 10
    disk_type    = "pd-standard"
    image_type   = "COS"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_container_node_pool" "kubeip_node" {
  name       = "kubeip-node"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary_cluster.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-micro"
    disk_size_gb = 10
    disk_type    = "pd-standard"
    image_type   = "COS"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/service.management",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

resource "google_compute_firewall" "gke_nodeport_allow" {
  name        = "gke-nodeport-allow"
  network     = "default"
  description = "Allow connections to our GKE node port"
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["30000"]
  }

  source_ranges = ["0.0.0.0/0"]
}
