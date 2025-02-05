#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
MAGENTA_COLOR="\e[35m"
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

# Authenticate and list active accounts
echo -e "${BOLD_TEXT}${YELLOW_COLOR}Listing authenticated accounts...${RESET_FORMAT}${NO_COLOR}"
gcloud auth list

# Clone the repository
echo -e "${BOLD_TEXT}${BLUE_TEXT}Cloning the Data Science on Google Cloud repository...${RESET_FORMAT}${NO_COLOR}"
git clone https://github.com/GoogleCloudPlatform/data-science-on-gcp/

cd data-science-on-gcp/03_sqlstudio || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to change directory.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

# Set environment variables
echo -e "${BOLD_TEXT}${YELLOW_COLOR}Setting environment variables...${RESET_FORMAT}${NO_COLOR}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export BUCKET=${PROJECT_ID}-ml

echo -e "${BOLD_TEXT}${GREEN_TEXT}Project ID: $PROJECT_ID${RESET_FORMAT}${NO_COLOR}"
echo -e "${BOLD_TEXT}${GREEN_TEXT}Bucket: $BUCKET${RESET_FORMAT}${NO_COLOR}"

# Copy SQL file to Cloud Storage
echo -e "${BOLD_TEXT}${BLUE_TEXT}Uploading SQL file to Cloud Storage...${RESET_FORMAT}${NO_COLOR}"
gsutil cp create_table.sql gs://$BUCKET/create_table.sql || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to upload SQL file.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

echo -e "${BOLD_TEXT}${GREEN_TEXT}SQL file staged successfully.${RESET_FORMAT}${NO_COLOR}"

# Create Cloud SQL instance
echo -e "${BOLD_TEXT}${BLUE_TEXT}Creating Cloud SQL instance...${RESET_FORMAT}${NO_COLOR}"
REGION="us-central1" # Modify if needed
gcloud sql instances create flights \
    --database-version=POSTGRES_13 --cpu=2 --memory=8GiB \
    --region=$REGION --root-password=Passw0rd || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to create Cloud SQL instance.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

echo -e "${BOLD_TEXT}${GREEN_TEXT}Cloud SQL instance created successfully.${RESET_FORMAT}${NO_COLOR}"

# Allowlist Cloud Shell IP
echo -e "${BOLD_TEXT}${YELLOW_COLOR}Fetching Cloud Shell IP and allowlisting...${RESET_FORMAT}${NO_COLOR}"
export ADDRESS=$(curl -s http://ipecho.net/plain)/32
gcloud sql instances patch flights --authorized-networks $ADDRESS --quiet || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to allowlist Cloud Shell.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

echo -e "${BOLD_TEXT}${GREEN_TEXT}Cloud Shell IP allowlisted successfully.${RESET_FORMAT}${NO_COLOR}"

# Create Database
echo -e "${BOLD_TEXT}${BLUE_TEXT}Creating database in Cloud SQL instance...${RESET_FORMAT}${NO_COLOR}"
export INSTANCE_NAME=flights
export DATABASE_NAME=bts
export SQL_FILE=create_table.sql
gcloud sql databases create $DATABASE_NAME --instance=$INSTANCE_NAME || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to create database.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

echo -e "${BOLD_TEXT}${GREEN_TEXT}Database created successfully.${RESET_FORMAT}${NO_COLOR}"

# Grant Storage access to Cloud SQL service account
echo -e "${BOLD_TEXT}${YELLOW_COLOR}Granting Storage access to Cloud SQL service account...${RESET_FORMAT}${NO_COLOR}"
SERVICE_ACCOUNT_EMAIL=$(gcloud sql instances describe $INSTANCE_NAME --format='value(serviceAccountEmailAddress)')
gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:roles/storage.objectViewer gs://$BUCKET || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to assign IAM role.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

echo -e "${BOLD_TEXT}${GREEN_TEXT}IAM role assigned successfully.${RESET_FORMAT}${NO_COLOR}"

# Import SQL file
echo -e "${BOLD_TEXT}${BLUE_TEXT}Importing SQL file into the database...${RESET_FORMAT}${NO_COLOR}"
gcloud sql import sql $INSTANCE_NAME \
    gs://$BUCKET/$SQL_FILE \
    --database=$DATABASE_NAME \
    --quiet || { echo -e "${BOLD_TEXT}${RED_TEXT}Failed to import SQL file.${RESET_FORMAT}${NO_COLOR}"; exit 1; }

echo -e "${BOLD_TEXT}${GREEN_TEXT}SQL file imported successfully.${RESET_FORMAT}${NO_COLOR}"

echo
echo -e "\e[1;31mDeleting the script (arcadecrew.sh) for safety purposes...\e[0m"
rm -- "$0"
echo
echo
# Completion message
echo -e "${MAGENTA_COLOR}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo