#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Start of the script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Instructions for the user
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Enabling required Google Cloud services...${RESET_FORMAT}"
echo

gcloud services enable aiplatform.googleapis.com storage-component.googleapis.com dataflow.googleapis.com artifactregistry.googleapis.com dataplex.googleapis.com compute.googleapis.com dataform.googleapis.com notebooks.googleapis.com datacatalog.googleapis.com visionai.googleapis.com 

sleep 30

# Instructions for the user
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Creating a new notebook instance...${RESET_FORMAT}"
echo

# Create a new notebook instance
gcloud notebooks instances create my-notebook --location=$ZONE --vm-image-project=deeplearning-platform-release --vm-image-family=tf-2-11-cu113-notebooks --machine-type=e2-standard-2

# Instructions for the user
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Accessing your notebook instance...${RESET_FORMAT}"
echo

echo "########################## Click the link below ##########################"
echo "${GREEN_TEXT}${BOLD_TEXT}Click the link on here:${RESET_FORMAT} https://console.cloud.google.com/vertex-ai/workbench/user-managed?cloudshell=true&project=$DEVSHELL_PROJECT_ID"
echo

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}NOW FOLLOW VIDEO INSTRUCTIONS...${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
