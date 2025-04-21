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
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}             INITIATING EXECUTION          ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

INSTANCE_ID="quickstart-instance"
CLUSTER_ID="${INSTANCE_ID}-c1"
STORAGE_TYPE="SSD"
TABLE_NAME="my-table"
COLUMN_FAMILY="cf1"

# Attempt to get dynamic values, fallback to defaults
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "YOUR_PROJECT_ID") # Replace YOUR_PROJECT_ID if needed
REGION=$(gcloud config get-value compute/region 2>/dev/null || echo "us-central1")
ZONE=$(gcloud config get-value compute/zone 2>/dev/null || echo "${REGION}-b")

echo "Using Project: $PROJECT_ID, Region: $REGION, Zone: $ZONE"

# Exit immediately if a command exits with a non-zero status.
set -e

# === Task 1: Create Bigtable instance ===
echo "Task 1: Creating Bigtable instance..."
gcloud bigtable instances create ${INSTANCE_ID} --project=${PROJECT_ID} \
    --display-name="${INSTANCE_ID}" \
    --instance-type=PRODUCTION \
    --cluster="${CLUSTER_ID}" \
    --cluster-zone="${ZONE}" \
    --cluster-storage-type=${STORAGE_TYPE} & # Run in background to allow script to continue

echo "Instance creation started in the background. Wait for completion in the Console."


# === Task 2: Connect to your instance (Configure cbt) ===
echo "Task 2: Configuring cbt..."
echo project = ${PROJECT_ID} > ~/.cbtrc
echo instance = ${INSTANCE_ID} >> ~/.cbtrc
echo " ~/.cbtrc configured."


# === Task 3: Read and write data ===
echo "Task 3: Working with table '${TABLE_NAME}'..."

# Consider adding a manual prompt or a sleep here if needed.
# echo "Pausing for 60 seconds to allow instance creation..."
# sleep 60

echo "Creating table..."
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" createtable ${TABLE_NAME}

echo "Listing tables:"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" ls

echo "Creating column family '${COLUMN_FAMILY}'..."
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" createfamily ${TABLE_NAME} ${COLUMN_FAMILY}

echo "Listing column families:"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" ls ${TABLE_NAME}

echo "Writing data..."
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" set ${TABLE_NAME} r1 ${COLUMN_FAMILY}:c1="test-value"

echo "Reading data:"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" read ${TABLE_NAME}

echo "Deleting table..."
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" deletetable ${TABLE_NAME}

# You can remove the set -e if you want the script to attempt subsequent commands even if one fails.
set +e

echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
