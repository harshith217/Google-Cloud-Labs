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

export ZONE=us-central1-a

echo ""

read -p "${YELLOW_COLOR}${BOLD_TEXT}ENTER PROJECT_ID_1: ${RESET_FORMAT}" PROJECT_ID_1
echo
read -p "${YELLOW_COLOR}${BOLD_TEXT}ENTER PROJECT_ID_2: ${RESET_FORMAT}" PROJECT_ID_2
echo
read -p "${YELLOW_COLOR}${BOLD_TEXT}ENTER PROJECT_ID_3: ${RESET_FORMAT}" PROJECT_ID_3
echo

echo "${BOLD_TEXT}${GREEN_TEXT}Connecting to worker-1-server and installing NGINX${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_2

gcloud compute ssh --zone "$ZONE" "worker-1-server" --project "$PROJECT_ID_2" --quiet --command "sudo apt-get update && sudo apt-get install -y nginx && ps auwx | grep nginx"
sleep 15

echo

echo "${BOLD_TEXT}${RED_TEXT}Connecting to worker-2-server and installing NGINX${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_3

gcloud compute ssh --zone "$ZONE" "worker-2-server" --project "$PROJECT_ID_3" --quiet --command "sudo apt-get update && sudo apt-get install -y nginx && ps auwx | grep nginx"

echo

echo "${BOLD_TEXT}${YELLOW_COLOR}Applying labels to worker-1-server${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_2

gcloud compute instances update worker-1-server \
    --update-labels=component=frontend,stage=dev \
    --zone=$ZONE

echo

echo "${BOLD_TEXT}${YELLOW_COLOR}Applying labels to worker-2-server${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_3

gcloud compute instances update worker-2-server \
    --update-labels=component=frontend,stage=test \
    --zone=$ZONE

gcloud config set project $PROJECT_ID_1

echo

echo "${BOLD_TEXT}${YELLOW_COLOR}Setting up an Email Notification Channel${RESET_FORMAT}"
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "ArcadeCrew",
  "description": "Subscribe to ArcadeCrew",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"

echo
echo "${BOLD_TEXT}${BLUE_TEXT}Please follow the video guide to complete the remaining steps.${RESET_FORMAT}"
echo
echo "https://console.cloud.google.com/monitoring/settings/add-projects?project=$PROJECT_ID_1"
echo

# Completion message
# echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
# echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

