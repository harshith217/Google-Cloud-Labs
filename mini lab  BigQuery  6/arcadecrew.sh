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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Error handling function
function error_exit {
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}" >&2
}

# Function to display section headers
function display_section {
    echo ""
    echo "${BLUE_TEXT}${BOLD_TEXT}$1${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}$(printf '=%.0s' {1..50})${RESET_FORMAT}"
}

# Function to check command success
function check_success {
    if [ $? -eq 0 ]; then
        echo "${GREEN_TEXT}${BOLD_TEXT}✓ SUCCESS: $1${RESET_FORMAT}"
    else
        error_exit "$2"
    fi
}


# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
check_success "Retrieved project ID: $PROJECT_ID" "Failed to get project ID"

display_section "Determining Dataset and Table Names"

# List datasets to identify the correct one
echo "${YELLOW_TEXT}${BOLD_TEXT}Listing available BigQuery datasets in project...${RESET_FORMAT}"
bq ls --project_id=$PROJECT_ID

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the dataset name:${RESET_FORMAT}"
read DATASET_NAME

echo "${YELLOW_TEXT}${BOLD_TEXT}Listing tables in dataset $DATASET_NAME...${RESET_FORMAT}"
bq ls --project_id=$PROJECT_ID "$DATASET_NAME"

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the source table name (Table1):${RESET_FORMAT}"
read SOURCE_TABLE
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the backup table name (Table2):${RESET_FORMAT}"
read BACKUP_TABLE


display_section "Creating Monthly Scheduled Query for Backup"

# Enable the BigQuery Data Transfer Service if it's not already enabled
echo "${CYAN_TEXT}${BOLD_TEXT}Enabling BigQuery Data Transfer Service...${RESET_FORMAT}"
if gcloud services enable bigquerydatatransfer.googleapis.com; then
  echo "${GREEN_TEXT}${BOLD_TEXT}✓ SUCCESS: Enabled BigQuery Data Transfer Service${RESET_FORMAT}"
else
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠ WARNING: Could not enable BigQuery Data Transfer Service. It may already be enabled or you may not have permission.${RESET_FORMAT}"
  echo "${YELLOW_TEXT}${BOLD_TEXT}Continuing with the script...${RESET_FORMAT}"
fi

# Set region/location for the BigQuery Data Transfer Service
LOCATION="us" # Default location, may need adjustment based on your project

# Create the scheduled query using bq command
echo "${CYAN_TEXT}${BOLD_TEXT}Creating scheduled query to backup data monthly...${RESET_FORMAT}"
bq mk \
  --transfer_config \
  --project_id=$PROJECT_ID \
  --target_dataset=$DATASET_NAME \
  --display_name="Monthly Backup for $SOURCE_TABLE" \
  --params="{\"query\":\"$QUERY\", \"destination_table_name_template\":\"\", \"write_disposition\":\"WRITE_APPEND\"}" \
  --data_source=scheduled_query \
  --schedule="1st day of month 00:00" \
  --location=$LOCATION

# If we're here, the automated approach worked!
check_success "Created scheduled query for monthly backup" "Failed to create scheduled query"

display_section "Verification"
echo "${CYAN_TEXT}${BOLD_TEXT}Listing scheduled queries in project...${RESET_FORMAT}"
bq ls --project_id=$PROJECT_ID --transfer_config --transfer_location=$LOCATION

# Completion Message
echo

echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
