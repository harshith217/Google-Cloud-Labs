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

# Function for error handling
handle_error() {
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}"
}

# Function to display step information
display_step() {
    echo "${YELLOW_TEXT}${BOLD_TEXT}STEP: $1${RESET_FORMAT}"
}

# Function to display success message
display_success() {
    echo "${GREEN_TEXT}${BOLD_TEXT}SUCCESS: $1${RESET_FORMAT}"
}

# Get project ID dynamically
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    handle_error "Failed to get project ID"
fi

# Set variables based on the project
BUCKET_NAME="${PROJECT_ID}-bucket"
DATASET_NAME="customer_details"
TABLE_NAME="customers"
CSV_FILE="customers.csv"

echo "${BLUE_TEXT}${BOLD_TEXT}Project ID: ${PROJECT_ID}${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Bucket: ${BUCKET_NAME}${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Dataset: ${DATASET_NAME}${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Table: ${TABLE_NAME}${RESET_FORMAT}"

# Verify if the CSV file exists locally
display_step "Checking if ${CSV_FILE} exists locally"
if [ ! -f "${CSV_FILE}" ]; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Note: ${CSV_FILE} not found locally. Attempting to copy from bucket.${RESET_FORMAT}"
    gsutil cp "gs://${BUCKET_NAME}/${CSV_FILE}" . || handle_error "Failed to copy CSV file from bucket"
    display_success "CSV file copied from bucket"
else
    display_success "CSV file found locally"
fi

# Load schema from CSV file into BigQuery table
display_step "Loading schema from ${CSV_FILE} into ${TABLE_NAME} table"

# Check if table exists and load schema
if bq show "${DATASET_NAME}.${TABLE_NAME}" &>/dev/null; then
    echo "${YELLOW_TEXT}${BOLD_TEXT}Table already exists. Loading schema from CSV...${RESET_FORMAT}"
    
    # Option 1: Use a temp table approach
    TEMP_TABLE="${TABLE_NAME}_temp_$(date +%s)"
    
    # Create a temporary table with the desired schema
    bq load --autodetect --replace=true --source_format=CSV "${DATASET_NAME}.${TEMP_TABLE}" "${CSV_FILE}" || handle_error "Failed to create temporary table"
    
    # Extract schema directly using bq's schema output format
    bq show --schema "${DATASET_NAME}.${TEMP_TABLE}" > schema.json || handle_error "Failed to extract schema"
    
    # Update the original table with the schema (using the right format)
    bq update --schema "$(cat schema.json)" "${DATASET_NAME}.${TABLE_NAME}" || handle_error "Failed to update table schema"
    
    # Clean up the temporary table
    bq rm -f "${DATASET_NAME}.${TEMP_TABLE}" || echo "Note: Could not remove temporary table ${TEMP_TABLE}"
else
    echo "${YELLOW_TEXT}${BOLD_TEXT}Table does not exist. Creating new table with schema from CSV...${RESET_FORMAT}"
    
    # Create table with schema from CSV but no data
    bq load --autodetect --source_format=CSV --schema_only "${DATASET_NAME}.${TABLE_NAME}" "${CSV_FILE}" || handle_error "Failed to create table with schema from CSV"
fi

display_success "Schema loaded successfully from ${CSV_FILE} into ${TABLE_NAME} table"

# Verify the table structure was updated properly
display_step "Verifying table schema"
bq show --schema "${DATASET_NAME}.${TABLE_NAME}" > current_schema.json || handle_error "Schema verification failed"
display_success "Table schema verified successfully"

# Completion Message
echo

echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
