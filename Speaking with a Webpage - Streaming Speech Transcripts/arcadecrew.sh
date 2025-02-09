#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=$'\033[0;34m'

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Stopping any running Jetty server on the VM instance...${RESET_FORMAT}"
gcloud compute ssh "speaking-with-a-webpage" --zone "$ZONE" --project "$DEVSHELL_PROJECT_ID" --quiet --command "pkill -f 'java.*jetty'"

sleep 5

echo
echo "${BLUE_TEXT}${BOLD_TEXT}Starting the WebAudio application on the VM instance...${RESET_FORMAT}"
gcloud compute ssh "speaking-with-a-webpage" --zone "$ZONE" --project "$DEVSHELL_PROJECT_ID" --quiet --command "cd ~/speaking-with-a-webpage/02-webaudio && mvn clean jetty:run"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}The WebAudio application is now running!${RESET_FORMAT}"


# # Safely delete the script if it exists
# SCRIPT_NAME="arcadecrew.sh"
# if [ -f "$SCRIPT_NAME" ]; then
#     echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
#     rm -- "$SCRIPT_NAME"
# fi

echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
