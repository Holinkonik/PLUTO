output "pluto_bucket_name" {
  description = "Name of the GCS bucket created for PLUTO."
  value       = google_storage_bucket.pluto_bucket.name
}

output "bigquery_dataset_id" {
  description = "ID of the BigQuery dataset."
  value       = google_bigquery_dataset.activities_dataset.dataset_id
}

output "bigquery_table_id" {
  description = "ID of the BigQuery resources table."
  value       = google_bigquery_table.resources_table.table_id
}

output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for activities."
  value       = google_pubsub_topic.activities_topic.name
}

output "cloud_function_name" {
  description = "Name of the deployed Cloud Function (2nd Gen)."
  value       = google_cloudfunctions2_function.pluto_function_v2.name
}

output "cloud_function_uri" {
  description = "URI of the Cloud Function (2nd Gen) service."
  value       = google_cloudfunctions2_function.pluto_function_v2.service_config[0].uri
  sensitive   = true
}

output "cloud_function_event_trigger_pubsub_topic" {
  description = "Pub/Sub topic that triggers the Cloud Function (2nd Gen)."
  value       = google_cloudfunctions2_function.pluto_function_v2.event_trigger[0].pubsub_topic
}

output "asset_feed_name" {
  description = "Name of the Cloud Asset feed."
  value       = google_cloud_asset_project_feed.activities_feed.name
}

output "cloud_function_service_account_email" {
  description = "Email of the service account used by the Cloud Function."
  value       = google_service_account.cf_sa.email
}

output "artifact_registry_repository_id" {
  description = "ID of the Artifact Registry repository for function images."
  value       = google_artifact_registry_repository.pluto_function_repo.id
}

output "artifact_registry_repository_name" {
  description = "Name of the Artifact Registry repository for function images."
  value       = google_artifact_registry_repository.pluto_function_repo.name # This is the repository_id part
} 