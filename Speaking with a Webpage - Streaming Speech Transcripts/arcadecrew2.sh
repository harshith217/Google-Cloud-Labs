#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
MAGENTA_COLOR="\e[35m"
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

export ZONE=$(gcloud compute instances list speaking-with-a-webpage --format 'csv[no-heading](zone)')

export VM_EXT_IP=$(gcloud compute instances describe speaking-with-a-webpage --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "${CYAN}${BOLD}Click here: "${RESET}""${BLUE}${BOLD}""https://$VM_EXT_IP:8443"""${RESET}"

echo