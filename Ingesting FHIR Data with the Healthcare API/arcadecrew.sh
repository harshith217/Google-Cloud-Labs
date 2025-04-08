#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "Enter the location: " LOCATION
export LOCATION=$LOCATION
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export PROJECT_NUMBER=$(gcloud projects list --filter=projectId:$PROJECT_ID \
  --format="value(projectNumber)")
export DATASET_ID=dataset1
export FHIR_STORE_ID=fhirstore1
export TOPIC=fhir-topic
export HL7_STORE_ID=hl7v2store1

gcloud services enable healthcare.googleapis.com

sleep 20

gcloud pubsub topics create $TOPIC

bq --location=$LOCATION mk --dataset --description HCAPI-dataset $PROJECT_ID:$DATASET_ID

bq --location=$LOCATION mk --dataset --description HCAPI-dataset-de-id $PROJECT_ID:de_id

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/bigquery.dataEditor
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-healthcare.iam.gserviceaccount.com \
--role=roles/bigquery.jobUser

gcloud healthcare datasets create $DATASET_ID \
--location=$LOCATION

gcloud healthcare fhir-stores create $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --version=R4

gcloud healthcare fhir-stores update $FHIR_STORE_ID \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --pubsub-topic=projects/$PROJECT_ID/topics/$TOPIC

gcloud healthcare fhir-stores create de_id \
  --dataset=$DATASET_ID \
  --location=$LOCATION \
  --version=R4

gcloud healthcare fhir-stores import gcs $FHIR_STORE_ID \
--dataset=$DATASET_ID \
--location=$LOCATION \
--gcs-uri=gs://spls/gsp457/fhir_devdays_gcp/fhir1/* \
--content-structure=BUNDLE_PRETTY

gcloud healthcare fhir-stores export bq $FHIR_STORE_ID \
--dataset=$DATASET_ID \
--location=$LOCATION \
--bq-dataset=bq://$PROJECT_ID.$DATASET_ID \
--schema-type=analytics

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}*****************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}       NOW FOLLOW VIDEO STEPS...         ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}*****************************************${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/healthcare/browser? ${RESET_FORMAT}"

echo "${RED_TEXT}${BOLD_TEXT}Have you completed the video steps? (y/n): ${RESET_FORMAT}"
read -r answer
if [[ $answer == "y" || $answer == "Y" ]]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Great! Proceeding with the next steps...${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}Please complete the video steps before proceeding.${RESET_FORMAT}"
fi
echo

sleep 180

gcloud healthcare fhir-stores export bq de_id \
--dataset=$DATASET_ID \
--location=$LOCATION \
--bq-dataset=bq://$PROJECT_ID.de_id \
--schema-type=analytics


echo
echo "${YELLOW_TEXT}${BOLD_TEXT}*****************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}       NOW FOLLOW VIDEO STEPS...         ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}*****************************************${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}OPEN THIS LINK: ${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/bigquery? ${RESET_FORMAT}"

# Completion Message
# echo
# echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo