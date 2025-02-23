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

# Step 1: Take Zone as Input
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT}"
read -r ZONE

# Derive Region from Zone
REGION=$(echo "$ZONE" | awk -F'-' '{print $1"-"$2}')
if [[ -z "$REGION" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}Invalid zone format. Please enter a valid zone (e.g., us-central1-a).${RESET_FORMAT}"
  exit 1
fi

# Step 2: Define Variables
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
INSTANCE_NAME="lab-workbench"
BUCKET_NAME="${PROJECT_ID}-labconfig-bucket"

# Validate Project ID
if [[ -z "$PROJECT_ID" ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}Project ID is not set. Please configure your project using 'gcloud config set project PROJECT_ID'.${RESET_FORMAT}"
  exit 1
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Project ID: ${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Region: ${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone: ${ZONE}${RESET_FORMAT}"

# Step 3: Enable Required APIs
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required APIs...${RESET_FORMAT}"
gcloud services enable aiplatform.googleapis.com storage-component.googleapis.com dataflow.googleapis.com artifactregistry.googleapis.com dataplex.googleapis.com compute.googleapis.com dataform.googleapis.com notebooks.googleapis.com datacatalog.googleapis.com visionai.googleapis.com 

sleep 30

# Step 4: Create Vertex AI Workbench Instance
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Vertex AI Workbench instance...${RESET_FORMAT}"
gcloud notebooks instances create $INSTANCE_NAME \
  --project=$PROJECT_ID \
  --location=$ZONE \
  --machine-type=e2-medium \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=common-cpu
if [[ $? -ne 0 ]]; then
  echo "${RED_TEXT}${BOLD_TEXT}Failed to create Vertex AI Workbench instance. Please check your configuration and try again.${RESET_FORMAT}"
  exit 1
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Vertex AI Workbench instance created successfully.${RESET_FORMAT}"

# Step 5: Wait for Instance to be Ready
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for the instance to be ready...${RESET_FORMAT}"
while [[ $(gcloud notebooks instances list --location=$ZONE --format="value(STATE)") != "ACTIVE" ]]; do
  echo "${CYAN_TEXT}Instance is not ready yet. Waiting for 30 seconds...${RESET_FORMAT}"
  sleep 30
done

echo "${GREEN_TEXT}${BOLD_TEXT}Vertex AI Workbench instance is now active.${RESET_FORMAT}"
echo

echo "########################## Click the link below ##########################"
echo "${GREEN_TEXT}${BOLD_TEXT}Click here:${RESET_FORMAT} https://console.cloud.google.com/vertex-ai/workbench/user-managed?cloudshell=true&project=$DEVSHELL_PROJECT_ID"
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
