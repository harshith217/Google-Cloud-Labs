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

echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION: ${RESET_FORMAT}" REGION

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Fetching the current GCP project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID fetched successfully: ${PROJECT_ID}${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a Docker repository named 'example-docker-repo' in the specified region...${RESET_FORMAT}"
gcloud artifacts repositories create example-docker-repo --repository-format=docker \
        --location=$REGION --description="Docker repository" \
        --project=$PROJECT_ID
echo "${GREEN_TEXT}${BOLD_TEXT}Docker repository created successfully!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Listing all repositories in the current project...${RESET_FORMAT}"
gcloud artifacts repositories list \
        --project=$PROJECT_ID
echo "${GREEN_TEXT}${BOLD_TEXT}Repositories listed successfully!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Configuring Docker to authenticate with Artifact Registry...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev
echo "${GREEN_TEXT}${BOLD_TEXT}Docker authentication configured successfully!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Pulling a sample Docker image from Google Container Registry...${RESET_FORMAT}"
docker pull us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
echo "${GREEN_TEXT}${BOLD_TEXT}Sample Docker image pulled successfully!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Tagging the pulled image for pushing to Artifact Registry...${RESET_FORMAT}"
docker tag us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0 \
$REGION-docker.pkg.dev/$PROJECT_ID/example-docker-repo/sample-image:tag1
echo "${GREEN_TEXT}${BOLD_TEXT}Image tagged successfully!${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Pushing the tagged image to Artifact Registry...${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/$PROJECT_ID/example-docker-repo/sample-image:tag1
echo "${GREEN_TEXT}${BOLD_TEXT}Image pushed successfully to Artifact Registry!${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
