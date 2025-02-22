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

echo "${YELLOW_TEXT}Enter ZONE:${RESET_FORMAT}"
read -p "Zone: " ZONE
echo

# Enable necessary APIs
echo "${BLUE_TEXT}${BOLD_TEXT}Step 2: Enabling required Google Cloud APIs...${RESET_FORMAT}"
echo "${CYAN_TEXT}Enabling notebooks.googleapis.com...${RESET_FORMAT}"
gcloud services enable notebooks.googleapis.com

echo "${CYAN_TEXT}Enabling aiplatform.googleapis.com...${RESET_FORMAT}"
gcloud services enable aiplatform.googleapis.com
echo

# Create Notebook instance
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Creating the Jupyter Notebook instance...${RESET_FORMAT}"
export NOTEBOOK_NAME="awesome-jupyter"
export MACHINE_TYPE="e2-standard-2"

echo "${GREEN_TEXT}Creating instance with the following details:${RESET_FORMAT}"
echo "${YELLOW_TEXT}Notebook Name: ${NOTEBOOK_NAME}${RESET_FORMAT}"
echo "${YELLOW_TEXT}Machine Type: ${MACHINE_TYPE}${RESET_FORMAT}"
echo "${YELLOW_TEXT}Zone: ${ZONE}${RESET_FORMAT}"
echo

gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-2-11-cu113-notebooks \
  --machine-type=$MACHINE_TYPE

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Your Jupyter Notebook instance has been created successfully!${RESET_FORMAT}"
echo



# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo