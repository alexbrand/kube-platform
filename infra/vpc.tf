resource "random_pet" "vpc_name" {
  prefix = "vpc"
}

resource "google_compute_network" "main" {
  project                 = var.project_id
  name                    = "${random_pet.vpc_name.id}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  project       = var.project_id
  name          = "${random_pet.vpc_name.id}"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.main.self_link

  secondary_ip_range {
    range_name    = "${random_pet.vpc_name.id}-pods"
    ip_cidr_range = "10.244.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${random_pet.vpc_name.id}-services"
    ip_cidr_range = "10.96.0.0/16"
  }
}
