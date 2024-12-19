#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo ""

# Clone the HelloLoggingNodeJS repository
git clone https://github.com/haggman/HelloLoggingNodeJS.git

# Change into the HelloLoggingNodeJS folder
cd HelloLoggingNodeJS

# Update the runtime in app.yaml to nodejs20
sed -i 's/^runtime: .*/runtime: nodejs20/' app.yaml

# Prompt the user for the region
echo "Enter the region for App Engine (e.g., europe-west):"
read REGION

# Create a new App Engine app using the user-provided region
gcloud app create --region="$REGION"

# Deploy the application to App Engine
gcloud app deploy


echo ""
# Completion message
# echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
# echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

