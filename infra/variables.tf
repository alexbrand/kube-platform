variable "project_id" {
  description = "The Google Cloud Platform project ID that will contain the infrastructure."
}

variable "region" {
  description = "The Google Cloud Platform region for the infrastructure."
  default     = "us-east1"
}

variable "gke_cluster_zone" {
  description = "The zone for the GKE cluster."
  default     = "us-east1-c"
}
