#!/bin/bash

# IF YOU CHANGE THESE IN TERRAFORM, YOU MUST UPDATE THEM HERE!
REGION="us-central1"                           # Default from variables.tf
CLOUD_FUNCTION_NAME="pluto-asset-handler"      # Default from variables.tf
ASSET_FEED_NAME="activities"                   # Default from variables.tf

BQ_DATASET="activities"                        # From main.tf resource google_bigquery_dataset
BQ_TABLE="resources"                           # From main.tf resource google_bigquery_table
PUBSUB_TOPIC_NAME="activities"                 # From main.tf resource google_pubsub_topic
PUBSUB_SUBSCRIPTION_NAME="activities-catchall" # From main.tf resource google_pubsub_subscription

print_usage() {
  echo "Usage: $0 <project_id>"
  echo ""
  echo "Current values:"
  echo "  Region: ${REGION}"
  echo "  Cloud Function Name: ${CLOUD_FUNCTION_NAME}"
  echo "  Asset Feed Name: ${ASSET_FEED_NAME}"
  echo "  BigQuery Dataset: ${BQ_DATASET}"
  echo "  BigQuery Table: ${BQ_TABLE}"
  echo "  Pub/Sub Topic: ${PUBSUB_TOPIC_NAME}"
  echo "  Pub/Sub Subscription: ${PUBSUB_SUBSCRIPTION_NAME}"
}

check_resource() {
  local resource_name="$1"
  shift
  local gcloud_command="$@"
  local status_message=""

  echo -n "Checking ${resource_name}... "
  if output=$($gcloud_command 2>&1); then
    if [[ "$resource_name" == "Cloud Function"* ]]; then
      local func_state
      func_state=$(echo "$output" | grep -E "^state:" | awk '{print $2}')
      if [[ "$func_state" == "ACTIVE" ]]; then
        status_message="[SUCCESS] ${resource_name} is ACTIVE."
      else
        status_message="[FAILURE] ${resource_name} found but state is ${func_state} (Expected ACTIVE)."
        overall_status="FAILURE"
      fi
    elif [[ "$resource_name" == "Cloud Asset Feed"* && "$gcloud_command" == *"gcloud asset feeds describe"* ]]; then
        status_message="[SUCCESS] ${resource_name} exists."
    else
      status_message="[SUCCESS] ${resource_name} exists and is accessible."
    fi
  else
    if echo "$output" | grep -qE "(Not found|NOT_FOUND)"; then
      status_message="[FAILURE] ${resource_name} not found."
    elif echo "$output" | grep -qE "(PERMISSION_DENIED|does not have permission)"; then
      status_message="[FAILURE] Permission denied for ${resource_name}. Output: $output"
    else
      status_message="[FAILURE] Error checking ${resource_name}. Output: $output"
    fi
    overall_status="FAILURE"
  fi
  echo "$status_message"
}

# --- Argument Parsing ---
if [ "$#" -ne 1 ]; then
  print_usage
  exit 1
fi

PROJECT_ID="$1"
GCS_BUCKET_NAME="${PROJECT_ID}-bucket"                    # From main.tf: "${var.project_id}-bucket"
ARTIFACT_REGISTRY_REPO_NAME="${CLOUD_FUNCTION_NAME}-repo" # From main.tf: "${var.cloud_function_name}-repo"

echo "--- Starting PLUTO Deployment Validation ---"
echo "Project ID: ${PROJECT_ID}"
echo "(Using hardcoded values for other configurations - see script header)"
echo "-------------------------------------------"

overall_status="SUCCESS" # Assume success initially

# --- Validate Resources ---

# 1. GCS Bucket
check_resource "GCS Bucket (${GCS_BUCKET_NAME})" \
  gcloud storage buckets describe "gs://${GCS_BUCKET_NAME}" --project="${PROJECT_ID}"

# 2. BigQuery Dataset
check_resource "BigQuery Dataset (${BQ_DATASET})" \
  bq show --project_id="${PROJECT_ID}" "${PROJECT_ID}:${BQ_DATASET}"

# 3. BigQuery Table
check_resource "BigQuery Table (${BQ_DATASET}.${BQ_TABLE})" \
  bq show --project_id="${PROJECT_ID}" "${PROJECT_ID}:${BQ_DATASET}.${BQ_TABLE}"

# 4. Pub/Sub Topic
check_resource "Pub/Sub Topic (${PUBSUB_TOPIC_NAME})" \
  gcloud pubsub topics describe "${PUBSUB_TOPIC_NAME}" --project="${PROJECT_ID}"

# 5. Pub/Sub Subscription
check_resource "Pub/Sub Subscription (${PUBSUB_SUBSCRIPTION_NAME})" \
  gcloud pubsub subscriptions describe "${PUBSUB_SUBSCRIPTION_NAME}" --project="${PROJECT_ID}"

# 6. Cloud Function (2nd Gen)
check_resource "Cloud Function (${CLOUD_FUNCTION_NAME})" \
  gcloud functions describe "${CLOUD_FUNCTION_NAME}" --project="${PROJECT_ID}" --region="${REGION}" --gen2

# 7. Cloud Asset Feed
check_resource "Cloud Asset Feed (${ASSET_FEED_NAME})" \
  gcloud asset feeds describe "${ASSET_FEED_NAME}" --project="${PROJECT_ID}"

# 8. Artifact Registry Repository
check_resource "Artifact Registry Repository (${ARTIFACT_REGISTRY_REPO_NAME})" \
  gcloud artifacts repositories describe "${ARTIFACT_REGISTRY_REPO_NAME}" --project="${PROJECT_ID}" --location="${REGION}"

echo "-------------------------------------------"
if [ "$overall_status" == "SUCCESS" ]; then
  echo "Overall Validation Status: [SUCCESS]"
  echo "All checked PLUTO resources appear to be configured."
  echo "Note: This script does not validate the end-to-end data flow."
else
  echo "Overall Validation Status: [FAILURE]"
  echo "One or more PLUTO resource checks failed. Please review the output above."
fi
echo "--- Validation Complete ---"

exit $([ "$overall_status" == "SUCCESS" ] && echo 0 || echo 1)