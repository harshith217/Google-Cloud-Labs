#!/bin/bash

# Define text colors and formatting
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
clear # Clear the terminal screen

# --- Script Header ---
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}         STARTING EXECUTION...       ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "Enter the LANGUAGE: " LANGUAGE
read -p "Enter the LOCAL: " LOCAL
read -p "Enter the BIGQUERY ROLE: " BIGQUERY_ROLE
read -p "Enter the CLOUD STORAGE ROLE: " CLOUD_STORAGE_ROLE

# Informing user about enabling APIs
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling necessary Google Cloud APIs...${RESET_FORMAT}"
gcloud services enable \
    vision.googleapis.com \
    translate.googleapis.com \
    bigquery.googleapis.com \
    storage.googleapis.com \
    iam.googleapis.com \
    serviceusage.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}APIs have been successfully enabled.${RESET_FORMAT}"
echo

# Informing user about service account creation
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a service account...${RESET_FORMAT}"
gcloud iam service-accounts create sample-sa

# Informing user about adding IAM policy bindings
echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy bindings...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$BIGQUERY_ROLE

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$CLOUD_STORAGE_ROLE

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/serviceusage.serviceUsageConsumer

# Informing user about waiting period
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for changes to propagate...${RESET_FORMAT}"
sleep 120

# Informing user about key creation
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a key for the service account...${RESET_FORMAT}"
gcloud iam service-accounts keys create sample-sa-key.json --iam-account sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com

# Informing user about setting environment variable
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up environment variable...${RESET_FORMAT}"
export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/sample-sa-key.json

# Informing user about downloading Python script
echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading the Python script for analysis...${RESET_FORMAT}"
wget https://raw.githubusercontent.com/guys-in-the-cloud/cloud-skill-boosts/main/Challenge-labs/Integrate%20with%20Machine%20Learning%20APIs%3A%20Challenge%20Lab/analyze-images-v2.py

# Informing user about modifying the Python script
echo "${YELLOW_TEXT}${BOLD_TEXT}Modifying the Python script...${RESET_FORMAT}"
sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py

# Informing user about running the Python script
echo "${YELLOW_TEXT}${BOLD_TEXT}Running the Python script for analysis...${RESET_FORMAT}"
python3 analyze-images-v2.py

python3 analyze-images-v2.py $DEVSHELL_PROJECT_ID $DEVSHELL_PROJECT_ID

# Informing user about querying BigQuery
echo "${YELLOW_TEXT}${BOLD_TEXT}Querying BigQuery for results...${RESET_FORMAT}"
bq query --use_legacy_sql=false "SELECT locale,COUNT(locale) as lcount FROM image_classification_dataset.image_text_detail GROUP BY locale ORDER BY lcount DESC"

# Final message
echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo