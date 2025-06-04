# ------------------------------------------
# Enable necessary APIs
resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudasset" {
  project = var.project_id
  service = "cloudasset.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com" 
  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  project = var.project_id
  service = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# ------------------------------------------
# IAM
# Cloud Function Service Account
resource "google_service_account" "cf_sa" {
  project      = var.project_id
  account_id   = var.cloud_function_service_account_name
  display_name = "PLUTO Cloud Function Service Account"
}

resource "google_project_iam_member" "cf_sa_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

resource "google_project_iam_member" "cf_sa_pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

resource "google_project_iam_member" "cf_sa_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cf_sa.email}"
}

# Grant Cloud Build service account permission to write to Artifact Registry
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "cf_build_repo_writer" {
  project    = google_artifact_registry_repository.pluto_function_repo.project
  location   = google_artifact_registry_repository.pluto_function_repo.location
  repository = google_artifact_registry_repository.pluto_function_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_artifact_registry_repository.pluto_function_repo,
    data.google_project.project
  ]
}

# ------------------------------------------
# Artifact Registry to store Cloud Function images
resource "google_artifact_registry_repository" "pluto_function_repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.cloud_function_name}-repo"
  format        = "DOCKER"
  depends_on = [
    google_project_service.artifactregistry
  ]
}

# ------------------------------------------
# Cloud Storage Bucket
resource "google_storage_bucket" "pluto_bucket" {
  name                        = "${var.project_id}-bucket"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  depends_on = [
    google_project_service.pubsub
  ]
}

# BigQuery Dataset
resource "google_bigquery_dataset" "activities_dataset" {
  project    = var.project_id
  dataset_id = "activities"
  location   = var.region
  depends_on = [
    google_project_service.bigquery
  ]
}

# BigQuery Table
resource "google_bigquery_table" "resources_table" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.activities_dataset.dataset_id
  table_id   = "resources"
  schema = jsonencode([
    {
      "name" : "messages",
      "type" : "STRING",
      "mode" : "NULLABLE"
    }
  ])
}

# Pub/Sub Topic
resource "google_pubsub_topic" "activities_topic" {
  project    = var.project_id
  name       = "activities"
  depends_on = [
    google_project_service.pubsub
  ]
}

# Bucket to store Cloud Function source
resource "google_storage_bucket" "cf_source_bucket" {
  name                        = "${var.project_id}-pluto-cf-source"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "cf_source_archive" {
  name   = "source/${data.archive_file.cf_source_zip.output_md5}.zip"
  bucket = google_storage_bucket.cf_source_bucket.name
  source = data.archive_file.cf_source_zip.output_path # Path to the zipped function
}

# Data source for zipping the Cloud Function source code
data "archive_file" "cf_source_zip" {
  type        = "zip"
  source_dir  = "../cloudfunction"
  output_path = "${path.module}/cf_source.zip"
}

# Cloud Function 2nd Gen
resource "google_cloudfunctions2_function" "pluto_function_v2" {
  project  = var.project_id
  name     = var.cloud_function_name # e.g., pluto-asset-handler
  location = var.region
  description = "PLUTO Cloud Function (2nd Gen) to process asset changes"

  build_config {
    runtime     = "python312"
    entry_point = "pubsub_to_bigquery"
    environment_variables = {
      # Add any other necessary env vars here
    }
    source {
      storage_source {
        bucket = google_storage_bucket.cf_source_bucket.name
        object = google_storage_bucket_object.cf_source_archive.name
      }
    }
    # The image will be built by Cloud Build and stored in the specified Artifact Registry repo
    docker_repository = google_artifact_registry_repository.pluto_function_repo.id
  }

  service_config {
    max_instance_count = 1 
    min_instance_count = 0
    available_memory   = "256Mi"
    timeout_seconds    = 60
    service_account_email = google_service_account.cf_sa.email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.activities_topic.id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_service.cloudbuild,
    google_storage_bucket_object.cf_source_archive,
    google_service_account.cf_sa,
    google_project_iam_member.cf_sa_bq_editor,
    google_project_iam_member.cf_sa_pubsub_subscriber,
    google_project_iam_member.cf_sa_logging_writer,
    google_artifact_registry_repository_iam_member.cf_build_repo_writer
  ]
}

resource "google_pubsub_subscription" "activities_catchall_sub" {
  project = var.project_id
  name    = "activities-catchall"
  topic   = google_pubsub_topic.activities_topic.name

  ack_deadline_seconds = 60

  depends_on = [
    google_pubsub_topic.activities_topic
  ]
}

# Cloud Asset Feed
resource "google_cloud_asset_project_feed" "activities_feed" {
  provider   = google
  project    = var.project_id
  feed_id    = var.asset_feed_name
  content_type = "RESOURCE"
  asset_types = [
    "compute.googleapis.com/.*"
    # Add more types for future goals, e.g., "spanner.googleapis.com/Instance"
  ]

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.activities_topic.id
    }
  }

  condition {
    expression  = "true" # Optional: filter specific resources, e.g., resource.matchTag('123456789012/env', 'prod')"
    title       = "all_compute_resources"
  }

  depends_on = [
    google_pubsub_topic.activities_topic,
    google_project_service.cloudasset
  ]
}