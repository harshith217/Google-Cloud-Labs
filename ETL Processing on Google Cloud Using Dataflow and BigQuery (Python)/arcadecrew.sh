#!/bin/bash

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

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION: ${RESET_FORMAT}" REGION
export REGION=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Disabling the Dataflow API if already enabled...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com

echo "${MAGENTA_TEXT}${BOLD_TEXT}Enabling the Dataflow API...${RESET_FORMAT}"
gcloud services enable dataflow.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Copying example files from the public GCS bucket to your local environment...${RESET_FORMAT}"
gsutil -m cp -R gs://spls/gsp290/dataflow-python-examples .

export PROJECT=$(gcloud config get-value project)

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting the active project to: ${RESET_FORMAT}${GREEN_TEXT}${BOLD_TEXT}$PROJECT${RESET_FORMAT}"
gcloud config set project $PROJECT

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a regional bucket in your specified region: ${RESET_FORMAT}${GREEN_TEXT}${BOLD_TEXT}$REGION${RESET_FORMAT}"
gcloud storage buckets create gs://$PROJECT --location=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Copying data files to your newly created bucket...${RESET_FORMAT}"
gcloud storage cp gs://spls/gsp290/data_files/usa_names.csv gs://$PROJECT/data_files/
gcloud storage cp gs://spls/gsp290/data_files/head_usa_names.csv gs://$PROJECT/data_files/

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a BigQuery dataset named 'lake'...${RESET_FORMAT}"
bq mk lake

echo "${CYAN_TEXT}${BOLD_TEXT}Launching a Docker container with Python 3.8 for further processing...${RESET_FORMAT}"
cd ~
docker run -it -e PROJECT=$PROJECT -v $(pwd)/dataflow-python-examples:/dataflow python:3.8 /bin/bash

# echo
# echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
# echo

# echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
# echo
