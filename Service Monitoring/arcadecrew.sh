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

echo ""

read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter Region: ${RESET_FORMAT}" REGION
export REGION

gcloud auth list

git clone https://github.com/haggman/HelloLoggingNodeJS.git

cd HelloLoggingNodeJS

gcloud app create --region=$REGION

gcloud app deploy --quiet


cat > email-channel.json <<EOF_CP
{
  "type": "email",
  "displayName": "arcadecrew",
  "description": "Subscribe",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_CP

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"


echo ""
# Completion message
# echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
# echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

