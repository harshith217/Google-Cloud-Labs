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
echo

# Fetch the zone of the VM instance
export ZONE=$(gcloud compute instances list speaking-with-a-webpage --format 'csv[no-heading](zone)')

# Fetch the external IP of the VM instance
export VM_EXT_IP=$(gcloud compute instances describe speaking-with-a-webpage --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo
echo "${GREEN_TEXT}${BOLD_TEXT}VM instance details fetched successfully!${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Click the link below to access your application:${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}https://$VM_EXT_IP:8443${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}Important:${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Run the NEXT Commands in the Previous CloudShell Tab.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Do not close this terminal until you have completed all steps.${RESET_FORMAT}"
echo
