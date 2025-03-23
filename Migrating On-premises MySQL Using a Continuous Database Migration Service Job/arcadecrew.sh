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
error_exit() {
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}" >&2
    echo "${YELLOW_TEXT}${BOLD_TEXT}Exiting script. Please resolve the error and try again.${RESET_FORMAT}" >&2
}

# Success function
success_message() {
    echo "${GREEN_TEXT}${BOLD_TEXT}SUCCESS: $1${RESET_FORMAT}"
}

# Info function
info_message() {
    echo "${CYAN_TEXT}${BOLD_TEXT}INFO: $1${RESET_FORMAT}"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    error_exit "gcloud CLI is not installed. Please install it before running this script."
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    error_exit "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
fi

# Define API names
DB_MIGRATION_API="datamigration.googleapis.com"
SERVICE_NETWORKING_API="servicenetworking.googleapis.com"

# Function to check if an API is enabled
check_api_status() {
  local api=$1
  # Check if API is enabled
  gcloud services list --enabled --filter="NAME:${api}" --format="value(NAME)"
}

# Function to enable API if it's not enabled
enable_api() {
  local api=$1
  # Enable API
  echo "${BLUE_TEXT}${BOLD_TEXT}Enabling API: $api${RESET_FORMAT}"
  gcloud services enable $api
}

# Check Database Migration API
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Database Migration API status...${RESET_FORMAT}"
DB_MIGRATION_STATUS=$(check_api_status $DB_MIGRATION_API)
if [ -z "$DB_MIGRATION_STATUS" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Database Migration API is not enabled. Enabling it now...${RESET_FORMAT}"
  enable_api $DB_MIGRATION_API
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Database Migration API is already enabled.${RESET_FORMAT}"
fi

# Check Service Networking API
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Service Networking API status...${RESET_FORMAT}"
SERVICE_NETWORKING_STATUS=$(check_api_status $SERVICE_NETWORKING_API)
if [ -z "$SERVICE_NETWORKING_STATUS" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Service Networking API is not enabled. Enabling it now...${RESET_FORMAT}"
  enable_api $SERVICE_NETWORKING_API
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Service Networking API is already enabled.${RESET_FORMAT}"
fi

echo "${YELLOW_TEXT}${BOLD_TEXT}API check and enable process completed.${RESET_FORMAT}"

# Task 1: Get the connectivity information for the MySQL source instance
echo ""

# Get the internal IP of the MySQL VM
info_message "Retrieving internal IP of the dms-mysql-training-vm-v2 VM..."

MYSQL_VM_IP=$(gcloud compute instances describe dms-mysql-training-vm-v2 --format="get(networkInterfaces[0].networkIP)")

if [ -z "$MYSQL_VM_IP" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Could not automatically retrieve IP. Please enter the IP manually:${RESET_FORMAT}"
    read MYSQL_VM_IP
    if [ -z "$MYSQL_VM_IP" ]; then
        error_exit "No IP address provided. Exiting..."
    fi
fi

success_message "MySQL source VM internal IP: ${MYSQL_VM_IP}"
echo ""

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         NOW FOLLOW VIDEO STEPS CAREFULLY...              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
