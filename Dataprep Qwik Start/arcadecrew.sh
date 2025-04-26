#!/bin/bash
# Define text formatting variables
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
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

# Instruction before creating the bucket
echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️  Preparing to create a Google Cloud Storage bucket...${RESET_FORMAT}"
echo "${WHITE_TEXT}   This bucket will use your project ID (${BOLD_TEXT}$DEVSHELL_PROJECT_ID${RESET_FORMAT}${WHITE_TEXT}) as its name.${RESET_FORMAT}"
echo

gsutil mb gs://$DEVSHELL_PROJECT_ID/

echo # Add a blank line for spacing

# Instruction before creating the service identity
echo "${YELLOW_TEXT}${BOLD_TEXT}🔑  Setting up the Dataprep service identity...${RESET_FORMAT}"
echo "${WHITE_TEXT}   This step ensures Dataprep has the necessary permissions to operate.${RESET_FORMAT}"
echo

gcloud beta services identity create --service=dataprep.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Setup tasks completed successfully!${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}*******************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥        NOW FOLLOW VIDEO STEPS        🎥${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}*******************************************${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT} OPEN DATAPREP FROM HERE: ${RESET_FORMAT}"
echo "${WHITE_TEXT}${UNDERLINE_TEXT} https://console.cloud.google.com/dataprep ${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

