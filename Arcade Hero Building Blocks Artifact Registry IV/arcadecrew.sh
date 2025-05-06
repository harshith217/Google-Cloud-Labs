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

echo -e "${BLUE_TEXT}${BOLD_TEXT}🛠️  First, we'll determine the default Google Cloud region associated with your project.${RESET_FORMAT}"
 export REGION=$(gcloud compute project-info describe \
 --format="value(commonInstanceMetadata.items[google-compute-default-region])")
 
 echo -e "${GREEN_TEXT}${BOLD_TEXT}⚙️  Next, we're enabling the Artifact Registry API.${RESET_FORMAT}"
 gcloud services enable artifactregistry.googleapis.com
 
 echo -e "${YELLOW_TEXT}${BOLD_TEXT}📦  Now, let's create a new Docker repository. This repository, named 'container-registry', will be established in the '${REGION}' region and will serve as a home for your Docker images.${RESET_FORMAT}"
 gcloud artifacts repositories create container-registry \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker registry with cleanup policy"
 
 echo -e "${MAGENTA_TEXT}${BOLD_TEXT}🐍  Following that, we will create a Python repository. This repository, named 'python-registry', will also be set up in the '${REGION}' region and is intended for storing your Python packages.${RESET_FORMAT}"
 gcloud artifacts repositories create python-registry \
  --repository-format=python \
  --location=$REGION \
  --description="Python registry with cleanup policy"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Hope you found this video helpful! Consider subscribing to Arcade Crew for more! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo


