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

INSTANCE_ID="${YELLOW_TEXT}quickstart-instance${RESET_FORMAT}"
CLUSTER_ID="${YELLOW_TEXT}${INSTANCE_ID}-c1${RESET_FORMAT}"
STORAGE_TYPE="${YELLOW_TEXT}SSD${RESET_FORMAT}"
TABLE_NAME="${YELLOW_TEXT}my-table${RESET_FORMAT}"
COLUMN_FAMILY="${YELLOW_TEXT}cf1${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}ERROR:${RESET_FORMAT} Could not determine Project ID. Run '${YELLOW_TEXT}gcloud config set project YOUR_PROJECT_ID${RESET_FORMAT}'"
    exit 1
fi

REGION=$(gcloud config get-value compute/region 2>/dev/null)
ZONE=$(gcloud config get-value compute/zone 2>/dev/null)

if [[ -z "$REGION" ]]; then
    REGION="us-central1"
    echo "${YELLOW_TEXT}Warning:${RESET_FORMAT} Region not found, using default: ${GREEN_TEXT}$REGION${RESET_FORMAT}"
fi
if [[ -z "$ZONE" ]]; then
    ZONE="${REGION}-b"
    echo "${YELLOW_TEXT}Warning:${RESET_FORMAT} Zone not found, using default: ${GREEN_TEXT}$ZONE${RESET_FORMAT}"
fi

echo "Using Project: ${GREEN_TEXT}$PROJECT_ID${RESET_FORMAT}, Region: ${GREEN_TEXT}$REGION${RESET_FORMAT}, Zone: ${GREEN_TEXT}$ZONE${RESET_FORMAT}"

set -e

echo "${GREEN_TEXT}Task 1: Creating Bigtable instance '${INSTANCE_ID}'...${RESET_FORMAT}"
gcloud bigtable instances create ${INSTANCE_ID} --project=${PROJECT_ID} \
    --display-name="${INSTANCE_ID}" \
    --cluster-config="id=${CLUSTER_ID},zone=${ZONE}" \
    --cluster-storage-type=${STORAGE_TYPE}

echo "${YELLOW_TEXT}Instance creation command submitted. Provisioning takes several minutes.${RESET_FORMAT}"
echo "${CYAN_TEXT}-> IMPORTANT: Wait for instance '${INSTANCE_ID}' to show as 'Ready' in the Cloud Console before proceeding.${RESET_FORMAT}"
sleep 90 

echo "${GREEN_TEXT}Task 2: Configuring cbt...${RESET_FORMAT}"
echo project = ${PROJECT_ID} > ~/.cbtrc
echo instance = ${INSTANCE_ID} >> ~/.cbtrc
echo "${BLUE_TEXT}~/.cbtrc configured.${RESET_FORMAT}"

echo "${GREEN_TEXT}Task 3: Working with table '${TABLE_NAME}'...${RESET_FORMAT}"

echo "${YELLOW_TEXT}Attempting to delete table '${TABLE_NAME}' if it exists (ignore errors if not found)...${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" deletetable ${TABLE_NAME} || true

echo "${GREEN_TEXT}Creating table...${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" createtable ${TABLE_NAME}

echo "${BLUE_TEXT}Listing tables:${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" ls

echo "${GREEN_TEXT}Creating column family '${COLUMN_FAMILY}'...${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" createfamily ${TABLE_NAME} ${COLUMN_FAMILY}

echo "${BLUE_TEXT}Listing column families:${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" ls ${TABLE_NAME}

echo "${GREEN_TEXT}Writing data...${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" set ${TABLE_NAME} r1 ${COLUMN_FAMILY}:c1="test-value"

echo "${BLUE_TEXT}Reading data:${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" read ${TABLE_NAME}

echo "${RED_TEXT}Deleting table...${RESET_FORMAT}"
cbt -project "${PROJECT_ID}" -instance "${INSTANCE_ID}" deletetable ${TABLE_NAME}

set +e

echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
