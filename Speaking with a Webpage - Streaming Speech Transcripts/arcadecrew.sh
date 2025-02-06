#!/bin/bash

# Define color variables
YELLOW_COLOR='\033[0;33m'
MAGENTA_COLOR='\033[0;35m'
NO_COLOR='\033[0m'
BACKGROUND_RED='\033[41m'
GREEN_TEXT='\033[0;32m'
RED_TEXT='\033[0;31m'
BOLD_TEXT='\033[1m'
RESET_FORMAT='\033[0m'
BLUE_TEXT='\033[0;34m'
CYAN_TEXT='\033[0;36m'

# Display initiation message
echo -e "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

gcloud compute ssh "speaking-with-a-webpage" --zone "$ZONE" --project "$DEVSHELL_PROJECT_ID" --quiet --command "pkill -f 'java.*jetty'"

sleep 5

gcloud compute ssh "speaking-with-a-webpage" --zone "$ZONE" --project "$DEVSHELL_PROJECT_ID" --quiet --command "cd ~/speaking-with-a-webpage/02-webaudio && mvn clean jetty:run"

echo

echo -e "${MAGENTA_COLOR}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe to our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
