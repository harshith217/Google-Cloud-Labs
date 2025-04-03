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

# Define text formatting variables
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}---> Fetching region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Fetching zone
echo "${GREEN_TEXT}${BOLD_TEXT}---> Fetching zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Fetching project ID
echo "${GREEN_TEXT}${BOLD_TEXT}---> Fetching project ID...${RESET_FORMAT}"
PROJECT_ID=`gcloud config get-value project`

# Fetching project number
echo "${GREEN_TEXT}${BOLD_TEXT}---> Fetching project number...${RESET_FORMAT}"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Instruction for instance creation
echo "${MAGENTA_TEXT}${BOLD_TEXT}---> Creating a Compute Engine instance named 'instance-1'...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This instance will use the following configuration:${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}- Machine type: n1-standard-1${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}- Image family: debian-11${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}- Boot disk type: pd-standard${RESET_FORMAT}"
echo

# Creating instance
gcloud compute instances create instance-1 \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --machine-type=n1-standard-1 \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --boot-disk-type=pd-standard \
  --boot-disk-device-name=instance-1

# Instruction for instance deletion
echo "${RED_TEXT}${BOLD_TEXT}---> Deleting the Compute Engine instance named 'instance-1'...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This operation is performed to clean up resources.${RESET_FORMAT}"
echo

# Deleting instance
gcloud compute instances delete instance-1 \
  --project=$PROJECT_ID \
  --zone=$ZONE --quiet

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"