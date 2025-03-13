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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT}"
read -r ZONE
echo "${BLUE_TEXT}${BOLD_TEXT}Setting Zone to:${RESET_FORMAT} ${ZONE}"
export ZONE=$ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Authenticating with gcloud...${RESET_FORMAT}"
gcloud auth list

echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${BLUE_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${PROJECT_ID}"

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting Compute Region and Zone...${RESET_FORMAT}"
export REGION=${ZONE%-*}
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Copying tutorial files...${RESET_FORMAT}"
gsutil cp gs://spls/gsp497/gke-monitoring-tutorial.zip .

echo "${YELLOW_TEXT}${BOLD_TEXT}Extracting tutorial files...${RESET_FORMAT}"
unzip gke-monitoring-tutorial.zip
cd gke-monitoring-tutorial

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating GKE resources...${RESET_FORMAT}"
make create

echo "${YELLOW_TEXT}${BOLD_TEXT}Validating setup...${RESET_FORMAT}"
make validate

echo "${YELLOW_TEXT}${BOLD_TEXT}Cleaning up resources...${RESET_FORMAT}"
make teardown

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
