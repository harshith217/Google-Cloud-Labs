#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

gcloud services enable apikeys.googleapis.com

gcloud alpha services api-keys create --display-name="ArcadeCrew" 

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=ArcadeCrew")

API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

echo $API_KEY

echo
echo -e "\e[1;31mDeleting the script (arcadecrew.sh) for safety purposes...\e[0m"
rm -- "$0"
echo
echo
# Completion message
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo