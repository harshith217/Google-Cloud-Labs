#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo ""

read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter Zone: ${RESET_FORMAT}" ZONE
export ZONE


export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

curl https://storage.googleapis.com/cloud-training/gcpsec/labs/stackdriver-lab.tgz | tar -zxf -

cd stackdriver-lab

curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/linux_startup.sh

curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/setup.sh

sed -i 's/us-west1-b/$ZONE/g' setup.sh

./setup.sh


bq mk --dataset project_logs

sleep 20

export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="json(projectNumber)" --quiet | jq -r '.projectNumber')

SERVICE_ACCOUNT="linux-servers@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.dataEditor"


TABLE_ID=$(bq ls --project_id $DEVSHELL_PROJECT_ID --dataset_id project_logs --format=json | jq -r '.[0].tableReference.tableId')


bq query --use_legacy_sql=false \
"
SELECT
  logName, resource.type, resource.labels.zone, resource.labels.project_id,
FROM
  \`$DEVSHELL_PROJECT_ID.project_logs.$TABLE_ID\`
"

gcloud alpha logging sinks create vm_logs bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs --log-filter='resource.type="gce_instance"'

gcloud alpha logging sinks create load_bal_logs bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs --log-filter='resource.type="http_load_balancer"'

gcloud logging read "resource.type=gce_instance AND logName=projects/$DEVSHELL_PROJECT_ID/logs/syslog AND textPayload:SyncAddress" --limit 10 --format json

gcloud logging metrics create 403s \
    --project=$DEVSHELL_PROJECT_ID \
    --description="Subscribe" \
    --log-filter='resource.type="gce_instance" AND log_name="projects/'$DEVSHELL_PROJECT_ID'/logs/syslog"'



sleep 20 


export DEVSHELL_PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="json(projectNumber)" --quiet | jq -r '.projectNumber')

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-logging.iam.gserviceaccount.com" \
    --role="roles/bigquery.dataEditor"

gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:service-$PROJECT_NUMBER@gcp-sa-logging.iam.gserviceaccount.com"

echo ""
echo ""

PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}Click below link to go to BigQuery${RESET_FORMAT}"
echo "${BOLD_TEXT}${BLUE_TEXT}https://console.cloud.google.com/bigquery?project=${PROJECT_ID}${RESET_FORMAT}"

echo ""
# Completion message
# echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
# echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

