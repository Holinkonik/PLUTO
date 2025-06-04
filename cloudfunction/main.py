# Project PLUTO Starter Code
# Use as the base for a Cloud Run Function (or in a container)
# Tested with Cloud Run Function using Python 3.12 and eventarc
# Change entry point from hello_pubsub to pubsub_to_bigquery
# Ensure service account has permissions to pub/sub topic
# Update requirements file
# Assumes a dataset called activities exists
# Assumes a table call resources
# resources schema - single column:  message:string
import base64
import json
import functions_framework
from google.cloud import bigquery
from google.cloud.spanner_admin_instance_v1 import InstanceAdminClient

table_id = "activities.resources"
spanner_admin = InstanceAdminClient()


# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def pubsub_to_bigquery(cloud_event):
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode('utf-8') 
    print(pubsub_message)
    client = bigquery.Client()
    table = client.get_table(table_id)
    row_to_insert = [(pubsub_message,)]     # NOTE - the trailing comma is required for this case - it expects a tuple
    errors = client.insert_rows(table, row_to_insert)
    if errors == []:
        print("Row Inserted")
    else:
        print(errors)
    try:
        message_data = json.loads(pubsub_message)
        if is_new_spanner(message_data):
            drop_spanner(message_data)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from message: {e}")


def is_new_spanner(message):
    asset = message.get("asset")
    prior_state = message.get("priorAssetState")
    return asset and asset.get("assetType") == "spanner.googleapis.com/Instance" and prior_state == "DOES_NOT_EXIST"


def drop_spanner(message):
    try:
        asset = message.get("asset")
        asset_name = asset.get("name")
        operation = spanner_admin.delete_instance(name=asset_name)
        print(f"Spanner instance deletion initiated. Operation: {operation.operation.name}")
    except Exception as e:
        print(f"Error deleting Spanner instance: {e}")
