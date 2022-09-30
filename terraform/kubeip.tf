resource "google_compute_address" "ip_addresses" {
  count    = 1
  provider = google-beta
  name     = "kubeip-ip-${count.index}"
  labels = (
    { kubeip = "primary-cluster" }
  )
}

resource "google_service_account" "kubeip_service_account" {
  account_id   = "kubeip"
  display_name = "kubeip service account"
}

resource "google_project_iam_custom_role" "kubeip_role" {
  role_id     = "kubeip"
  title       = "kubeip"
  description = "The required permissions for kubeip to run"
  permissions = [
    "compute.addresses.list",
    "compute.instances.addAccessConfig",
    "compute.instances.deleteAccessConfig",
    "compute.instances.get",
    "compute.instances.list",
    "compute.projects.get",
    "container.clusters.get",
    "container.clusters.list",
    "resourcemanager.projects.get",
    "compute.networks.useExternalIp",
    "compute.subnetworks.useExternalIp",
    "compute.addresses.use",
  ]
}

resource "google_project_iam_binding" "kubeip_binding" {
  role    = google_project_iam_custom_role.kubeip_role.name
  project = var.gke_project
  members = [
    "serviceAccount:${google_service_account.kubeip_service_account.email}"
  ]
}
