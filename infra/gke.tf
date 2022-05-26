data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

resource "random_pet" "gke_cluster_name" {
  prefix = "cluster"
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.project_id
  name                       = random_pet.gke_cluster_name.id
  region                     = var.region
  regional                   = false
  zones                      = [var.gke_cluster_zone]
  network                    = google_compute_network.main.name
  subnetwork                 = google_compute_subnetwork.main.name
  ip_range_pods              = google_compute_subnetwork.main.secondary_ip_range[0].range_name
  ip_range_services          = google_compute_subnetwork.main.secondary_ip_range[1].range_name
  http_load_balancing        = true
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  datapath_provider          = "ADVANCED_DATAPATH"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  node_pools = [
    {
      name               = "node-pool-01"
      machine_type       = "e2-standard-4"
      min_count          = 0
      max_count          = 5
      local_ssd_count    = 0
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = 1
      enable_secure_boot = true
    },
  ]
}


resource "google_storage_bucket" "cluster_logs" {
  name          = "bucket-${random_pet.gke_cluster_name.id}-logs"
  project       = var.project_id
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_service_account" "loki_service_account" {
  account_id   = "cluster-monitoring-loki"
  display_name = "Cluster Monitoring: Loki"
}

resource "google_storage_bucket_iam_member" "loki_service_account_member" {
  bucket = google_storage_bucket.cluster_logs.name
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.loki_service_account.email}"
}

resource "google_service_account_iam_member" "loki_service_account_allow_workload_identity" {
  service_account_id = google_service_account.loki_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/loki]"
}
