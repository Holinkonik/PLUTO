#!/bin/bash

# Get the current active GCP project ID
CURRENT_GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)

# Check if gcloud command was successful and project ID was retrieved
if [ -z "$CURRENT_GCP_PROJECT" ]; then
  echo "Error: Could not retrieve current GCP project ID."
  echo "Please ensure you are authenticated with gcloud and have a project configured:"
  echo "  gcloud auth login"
  echo "  gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

# Define the path for the new .tfvars file
TFVARS_DIR="terraform"
DEV_TFVARS_FILE="terraform/dev.tfvars"
PROD_TFVARS_FILE="terraform/prod.tfvars"

# Create the terraform directory if it doesn't exist
mkdir -p "$TFVARS_DIR"

# Write the project_id to the *.tfvars file
# This will create the file if it doesn't exist, or overwrite it if it does.
echo "project_id=\"$CURRENT_GCP_PROJECT\"" > "$DEV_TFVARS_FILE"
echo "project_id=\"$CURRENT_GCP_PROJECT\"" > "$PROD_TFVARS_FILE"

# You can add other default variables here if needed, for example:
# echo "region=\"us-central1\"" >> "$TFVARS_FILE"

echo "Successfully created/updated $DEV_TFVARS_FILE & $PROD_TFVARS_FILE with:"
echo "project_id=\"$CURRENT_GCP_PROJECT\""

# Optional: Add a default region if you like
# DEFAULT_REGION="us-central1"
# echo "region=\"$DEFAULT_REGION\"" >> "$TFVARS_FILE"
# echo "region=\"$DEFAULT_REGION\" also added."