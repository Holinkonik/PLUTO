# PLUTO Demonstration Code
Project Logistics, UTilization and Operations (PLUTO)
 
## Clone in the Repo
Open Cloud Shell\
Clone in the `https://github.com/ROIGCP/PLUTO` repo\
    Command: `git clone https://github.com/ROIGCP/PLUTO`\
    Command: `cd PLUTO`

## PLUTO dependancies
Make sure you have a project set\
    Command: `gcloud config set project YOURPROJECTNAME`

Bucket named projectid-bucket\
    Command: `gcloud storage buckets create gs://$GOOGLE_CLOUD_PROJECT-bucket`
    
BigQuery Dataset called "activities"\
    Command: `bq mk activities`

BigQuery Table called "resources" - starting schema\
    Command: `bq mk --schema messages:STRING -t activities.resources`

Enable the Pub/Sub APIs\
    Command: `gcloud services enable pubsub.googleapis.com`
    Command: `gcloud services list`

PubSub Topic called "activities"\
    Command: `gcloud pubsub topics create activities`

PubSub Subscription called "activites-catchall"\
    Command : `gcloud pubsub subscriptions create activities-catchall --topic=projects/$GOOGLE_CLOUD_PROJECT/topics/activities`

Create a Cloud Function\
    Python \
    Trigger by topic activities \
    Use the sample in CloudFunction folder

## Google Asset Managment examples

Enable the Asset Manager and Cloud Resource Manager APIs\
    Command: `gcloud services enable cloudasset.googleapis.com`\
    Command: `gcloud services enable cloudresourcemanager.googleapis.com`\
    Command: `gcloud services list`

Asset Export to BigQuery Example\
(NOTE: It make take a few minutes after API enablement for this command to work)\
    Command: `gcloud asset export --project=$GOOGLE_CLOUD_PROJECT --bigquery-table=export --bigquery-dataset=activities`

Asset Feed Creation (to Pub/Sub)\
    Command: 
    `gcloud asset feeds create activities --project=$GOOGLE_CLOUD_PROJECT --content-type=resource --asset-types="compute.googleapis.com.*" --pubsub-topic=projects/$GOOGLE_CLOUD_PROJECT/topics/activities`

# Project Overview
## Executive statement

**P**roject **L**ogistics, **UT**ilization and **O**perations (**PLUTO**) is an automation framework to monitor projects for changes within **Moon Bank**. 

When new compute resources are created in a project, PLUTO uses the Google Asset Management API to capture the event into a Pub/Sub topic, which executes a Cloud Function and stored the results into BigQuery.

## Solution concept

PLUTO requires manual steps to be performed on each new project. 

These steps include:
- Enabling APIs
- Creating a Pub/Sub Topic and Subscription
- Creating a BigQuery Dataset 
- Subscribe the Google Asset Project
- Create and Deploy the Cloud Function using the PLUTO python code with the project parameters

The solution is to eliminate the toil of configuring a project using Terraform to automate the process.

## Existing technical environment

A working example project: **moonbank-pluto** is provided as a working example.
A github repository with sample code is located at **https://github.com/ROIGCP/PLUTO**

## Goals (before the next meeting)

- Each participant should deploy PLUTO to their assigned DEV project
- Create the terraform to deploy PLUTO to their assigned PROD project
- Display some basic information to Looker Studio (was called Data Studio) dashboard
	- To initialize Looker Studio- go to [https://lookerstudio.google.com](https://lookerstudio.google.com/) and complete the wizard
	- Do NOT try going via Looker in Console - that is for Looker (not Looker Studio) and is not required/enabled
- Add at least one new action to PLUTO
	- If you are not sure - ask your instructor for ideas
	- Feel free to work with others - Moon Bank is a TEAM effort!

## Additional Goals (over the next weeks, before the DevOps workshop)

- Capture the event of a user creating a Spanner database, and delete the Spanner database created
- Identity any virtual machines created with LocalSSDs 
- Implement Alerts that identifies if too many resources (more than 5) are created within a 2-minute period or after hours
- Create and utilize a service account for running the cloud function

## Requirements

- Implement PLUTO on GCP using your DEV project
- Automate the deployment of PLUTO to the assigned PROD project
- Follow Google's Best Practices for the products used
- Reduce infrastructure management time and cost
- Adopt the Google-recommended practices for cloud computing

## GCP Resources

- You will be provided with a ROI Moon Bank User and TWO Google Cloud Platform Projects (-dev and -prod)
- Infrastructure Automation should utilize Terraform
- When building computing resources - please use the minimal configuration necessary for operation, and shutdown when not in use.
- If utilizing any of the following resources, please follow this guidance
	- Cloud Run or Cloud Run Functions can all be used and left operational. DISABLE auto-retry    
    - Compute Engine: Limit CPU usage to e2-micro or e2-medium and shutdown VMs when not in use
    - Kubernetes Clusters: You should not need to utilize Kubernetes/GKE for this project
    - AppEngine: You should not need to utilize AppEngine (either Standard or Flex)
    - Cloud SQL Databases should be created at the MINIMAL configuration (Enterprise with shared core, NOT Enterprise Plus). Please do NOT configure high-availability or additional read-replicas
    - Spanner and BigTable Database should only be created for testing, and not left running for more than 1 hour

If expensive resources in your project are left running for an extended period of time OR if your project has excessive spend, your project will be disabled, and you will need to contact your [MoonbankSupport@roitraining.com](mailto:MoonbankSupport@roitraining.com) to have your project re-enabled.

# Terraform Steps

### Create workspaces for DEV & PROD

`$ terraform workspace new dev`

`$ terraform workspace new prod`

### Start deployment on DEV

`$ terraform plan -var-file="dev.tfvars" -out="dev.tfplan"`

`$ terraform apply "dev.tfplan"`

