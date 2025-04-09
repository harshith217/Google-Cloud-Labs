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

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}✓ Zone received. Proceeding with environment setup...${RESET_FORMAT}"
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter KEY_1 for labels: ${RESET_FORMAT}" KEY_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter VALUE_1 for labels: ${RESET_FORMAT}" VALUE_1

echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting up the environment variables based on your inputs...${RESET_FORMAT}"
export REGION="${ZONE%-*}"
echo "${GREEN_TEXT}${BOLD_TEXT}✓ REGION: ${WHITE_TEXT}${BOLD_TEXT}${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}✓ Using PROJECT_ID: ${WHITE_TEXT}${BOLD_TEXT}${DEVSHELL_PROJECT_ID}${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Dataplex Lake named 'Customer-Lake' in the specified region...${RESET_FORMAT}"
gcloud alpha dataplex lakes create customer-lake \
    --display-name="Customer-Lake" \
    --location=$REGION \
    --labels="key_1=$KEY_1,value_1=$VALUE_1"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Dataplex Zone named 'Public-Zone' under the lake...${RESET_FORMAT}"
gcloud dataplex zones create public-zone \
    --lake=customer-lake \
    --location=$REGION \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --display-name="Public-Zone"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating 'Customer Raw Data' asset linked to a Cloud Storage bucket...${RESET_FORMAT}"
gcloud dataplex assets create customer-raw-data \
    --location=$REGION \
    --lake=customer-lake \
    --zone=public-zone \
    --resource-type=STORAGE_BUCKET \
    --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-bucket \
    --discovery-enabled \
    --display-name="Customer Raw Data"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating 'Customer Reference Data' asset linked to a BigQuery dataset...${RESET_FORMAT}"
gcloud dataplex assets create customer-reference-data \
    --location=$REGION \
    --lake=customer-lake \
    --zone=public-zone \
    --resource-type=BIGQUERY_DATASET \
    --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_reference_data \
    --display-name="Customer Reference Data"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
