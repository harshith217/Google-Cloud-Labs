#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Displaying instructions
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the Compute Engine instance zone...${RESET_FORMAT}"
ZONE="$(gcloud compute instances list --project=$DEVSHELL_PROJECT_ID --format='value(ZONE)')"
echo "${GREEN_TEXT}Zone detected: $ZONE${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting up Google Cloud Project...${RESET_FORMAT}"
export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value core/project)
echo "${GREEN_TEXT}Project set to: $GOOGLE_CLOUD_PROJECT${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a service account...${RESET_FORMAT}"
gcloud iam service-accounts create my-natlang-sa \
  --display-name "my natural language service account"
echo "${GREEN_TEXT}Service account created successfully.${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Generating and saving service account key...${RESET_FORMAT}"
gcloud iam service-accounts keys create ~/key.json \
  --iam-account my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
echo "${GREEN_TEXT}Key saved as ~/key.json${RESET_FORMAT}"

export GOOGLE_APPLICATION_CREDENTIALS="/home/USER/key.json"

echo "${BLUE_TEXT}${BOLD_TEXT}Connecting to the Compute Engine instance...${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE" "linux-instance" --project "$DEVSHELL_PROJECT_ID" --quiet --command "gcloud ml language analyze-entities --content='Michelangelo Caravaggio, Italian painter, is known for \"The Calling of Saint Matthew\".' > result.json"
echo "${GREEN_TEXT}${BOLD_TEXT}Process completed.${RESET_FORMAT}"
echo

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
