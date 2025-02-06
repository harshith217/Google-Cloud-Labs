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

export ZONE=$(gcloud compute instances list speaking-with-a-webpage --format 'csv[no-heading](zone)')

export VM_EXT_IP=$(gcloud compute instances describe speaking-with-a-webpage --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Display clickable link
echo -e "${CYAN_TEXT}${BOLD_TEXT}Click here: ${RESET_FORMAT}${BLUE_TEXT}${BOLD_TEXT}https://$VM_EXT_IP:8443${RESET_FORMAT}"

echo
