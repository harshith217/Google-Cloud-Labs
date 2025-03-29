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

# Request region input
echo "${MAGENTA_TEXT}${BOLD_TEXT}ENTER REGION:${RESET_FORMAT}"
read -p "${GREEN_TEXT}> ${RESET_FORMAT}" REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Setting region to: ${WHITE_TEXT}$REGION${RESET_FORMAT}"
echo

gcloud config set compute/region $REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID-bucket/

echo "${YELLOW_TEXT}${BOLD_TEXT}Resetting Dataflow API (this may take a moment)...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT}Enabling Dataflow API...${RESET_FORMAT}"
gcloud services enable dataflow.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Starting Docker container to run Apache Beam pipelines...${RESET_FORMAT}"
echo "${YELLOW_TEXT}This will run both a local and cloud-based pipeline.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Please wait, this may take several minutes.${RESET_FORMAT}"
echo

docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID -e REGION=$REGION python:3.9 /bin/bash -c '

pip install "apache-beam[gcp]"==2.42.0 && \
python -m apache_beam.examples.wordcount --output OUTPUT_FILE && \
HUSTLER=gs://$DEVSHELL_PROJECT_ID-bucket && \
python -m apache_beam.examples.wordcount --project $DEVSHELL_PROJECT_ID \
  --runner DataflowRunner \
  --staging_location $HUSTLER/staging \
  --temp_location $HUSTLER/temp \
  --output $HUSTLER/results/output \
  --region $REGION
'

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo