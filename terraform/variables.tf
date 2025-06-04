variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for resources."
  type        = string
  default     = "us-central1"
}

variable "asset_feed_name" {
  description = "Name for the Cloud Asset feed."
  type        = string
  default     = "activities"
}

variable "cloud_function_name" {
  description = "Name for the Cloud Function."
  type        = string
  default     = "pluto-asset-handler"
}

variable "cloud_function_service_account_name" {
  description = "Name for the Cloud Function service account."
  type        = string
  default     = "dev14-pluto-cf-sa"
}