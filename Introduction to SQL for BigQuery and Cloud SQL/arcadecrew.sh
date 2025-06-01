#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
BG_BLUE=$'\033[44m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_RED=$'\033[41m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 📦 STEP 1: CLOUD STORAGE SETUP ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎯 Setting up Cloud Storage bucket for your project...${RESET_FORMAT}"
echo
gsutil mb gs://$DEVSHELL_PROJECT_ID || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to create bucket${RESET_FORMAT}"
}

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 📥 STEP 2: DATASET ACQUISITION ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔄 Fetching CSV dataset files from remote source...${RESET_FORMAT}"
echo
curl -O https://github.com/ArcadeCrew/Google-Cloud-Labs/raw/refs/heads/main/Introduction%20to%20SQL%20for%20BigQuery%20and%20Cloud%20SQL/start_station_name.csv || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to download start_station_name.csv${RESET_FORMAT}"
}

curl -O https://github.com/ArcadeCrew/Google-Cloud-Labs/raw/refs/heads/main/Introduction%20to%20SQL%20for%20BigQuery%20and%20Cloud%20SQL/end_station_name.csv || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to download end_station_name.csv${RESET_FORMAT}"
}

echo
echo "${BG_YELLOW}${BLACK_TEXT}${BOLD_TEXT} ☁️ STEP 3: FILE DEPLOYMENT ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Transferring downloaded files to Cloud Storage...${RESET_FORMAT}"
echo
gsutil cp start_station_name.csv gs://$DEVSHELL_PROJECT_ID/ || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to upload start_station_name.csv${RESET_FORMAT}"
}

gsutil cp end_station_name.csv gs://$DEVSHELL_PROJECT_ID/ || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to upload end_station_name.csv${RESET_FORMAT}"
}

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🌍 Detecting your project's geographical configuration...${RESET_FORMAT}"
echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [[ -z "$REGION" ]]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Region not found in project metadata.${RESET_FORMAT}"
    echo "${BG_RED}${WHITE_TEXT}${BOLD_TEXT} USER INPUT REQUIRED ${RESET_FORMAT}"
    echo -n "${CYAN_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}🌐 Please enter your region: ${RESET_FORMAT}"
    read REGION
fi

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 🗄️ STEP 4: DATABASE INFRASTRUCTURE ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}⚡ Provisioning Cloud SQL MySQL instance...${RESET_FORMAT}"
echo
gcloud sql instances create my-demo \
    --database-version=MYSQL_8_0 \
    --region=$REGION \
    --tier=db-f1-micro \
    --root-password=abhishek || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to create Cloud SQL instance${RESET_FORMAT}"
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🏗️ Building dedicated database schema...${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🚲 Creating 'bike' database for our cycling data${RESET_FORMAT}"
echo
gcloud sql databases create bike --instance=my-demo || {
    echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to create database${RESET_FORMAT}"
}

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}${BLINK_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
