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

echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the location: ${RESET_FORMAT}"
read LOCATION
export LOCATION=$LOCATION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting the compute region to the location you provided...${RESET_FORMAT}"
gcloud config set compute/region $LOCATION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket for your project...${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID-bucket/

echo "${MAGENTA_TEXT}${BOLD_TEXT}Disabling the Dataflow API temporarily...${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com
sleep 20

echo "${MAGENTA_TEXT}${BOLD_TEXT}Re-enabling the Dataflow API. This may take a few moments...${RESET_FORMAT}"
gcloud services enable dataflow.googleapis.com
sleep 20

echo "${MAGENTA_TEXT}${BOLD_TEXT}Starting a Docker container to run the Apache Beam pipeline...${RESET_FORMAT}"
docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID -e LOCATION=$LOCATION python:3.9 /bin/bash -c '
pip install "apache-beam[gcp]"==2.42.0 && \
python -m apache_beam.examples.wordcount --output OUTPUT_FILE && \
HUSTLER=gs://$DEVSHELL_PROJECT_ID-bucket && \
python -m apache_beam.examples.wordcount --project $DEVSHELL_PROJECT_ID \
  --runner DataflowRunner \
  --staging_location $HUSTLER/staging \
  --temp_location $HUSTLER/temp \
  --output $HUSTLER/results/output \
  --region $LOCATION
'

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
