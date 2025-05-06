#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}🛠️  Let's begin by identifying and setting your default Google Cloud region.${RESET_FORMAT}"
 export REGION=$(gcloud compute project-info describe \
 --format="value(commonInstanceMetadata.items[google-compute-default-region])")
 
echo -e "${GREEN_TEXT}${BOLD_TEXT}🔑  Next, we'll enable the Artifact Registry API.${RESET_FORMAT}"
 gcloud services enable artifactregistry.googleapis.com
 
echo -e "${YELLOW_TEXT}${BOLD_TEXT}🐳  Now, we're creating a Docker repository named 'container-registry'. This repository will be located in the $REGION region and will store your Docker container images.${RESET_FORMAT}"
 gcloud artifacts repositories create container-registry \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker registry with cleanup policy"
 
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}📦  Finally, we'll create an APT repository named 'apt-registry'. This will also be in the $REGION region and is designed to host your APT packages.${RESET_FORMAT}"
 gcloud artifacts repositories create apt-registry \
  --repository-format=apt \
  --location=$REGION \
  --description="APT registry with cleanup policy"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Hope you found this video helpful! Consider subscribing to Arcade Crew for more! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

