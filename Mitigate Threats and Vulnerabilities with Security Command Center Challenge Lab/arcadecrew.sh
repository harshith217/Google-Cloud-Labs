#!/bin/bash

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Clear the screen
clear

# Print the welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

gcloud scc muteconfigs create muting-flow-log-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --location=global \
  --description="Rule for muting VPC Flow Logs" \
  --filter="category=\"FLOW_LOGS_DISABLED\"" \
  --type=STATIC

gcloud scc muteconfigs create muting-audit-logging-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --location=global \
  --description="Rule for muting audit logs" \
  --filter="category=\"AUDIT_LOGGING_DISABLED\"" \
  --type=STATIC

gcloud scc muteconfigs create muting-admin-sa-findings \
  --project=$DEVSHELL_PROJECT_ID \
  --location=global \
  --description="Rule for muting admin service account findings" \
  --filter="category=\"ADMIN_SERVICE_ACCOUNT\"" \
  --type=STATIC

echo
echo "${GREEN_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              CHECK SCORE FOR TASK 2              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"

echo
read -p "${RED_TEXT}${BOLD_TEXT}Have you checked the progress for task 2 (Y/N)?${RESET_FORMAT}" response

if [[ "$response" =~ ^[Yy]$ ]]; then
  echo "${GREEN_TEXT}${BOLD_TEXT}Great! Let's proceed.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}Please check the progress before continuing.${RESET_FORMAT}"
fi
echo
# Delete the existing rule
gcloud compute firewall-rules delete default-allow-rdp

# Create a new rule with the updated source IP range
gcloud compute firewall-rules create default-allow-rdp \
  --source-ranges=35.235.240.0/20 \
  --allow=tcp:3389 \
  --description="Allow HTTP traffic from 35.235.240.0/20" \
  --priority=65534

# Delete the existing rule
gcloud compute firewall-rules delete default-allow-ssh --quiet

# Create a new rule with the updated source IP range
gcloud compute firewall-rules create default-allow-ssh \
  --source-ranges=35.235.240.0/20 \
  --allow=tcp:22 \
  --description="Allow HTTP traffic from 35.235.240.0/20" \
  --priority=65534

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

echo "${CYAN}${BOLD}OPEN THIS LINK: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/compute/instancesEdit/zones/$ZONE/instances/cls-vm?project=$DEVSHELL_PROJECT_ID"""${RESET}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              NOW FOLLOW VIDEO STEPS...              ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"

echo

read -p "${RED_TEXT}${BOLD_TEXT}Have you followed the video steps (Y/N)?${RESET_FORMAT}" response
if [[ "$response" =~ ^[Yy]$ ]]; then
  echo "${GREEN_TEXT}${BOLD_TEXT}Great! Let's proceed.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}Please follow the video steps before continuing.${RESET_FORMAT}"
fi

echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

export VM_EXT_IP=$(gcloud compute instances describe cls-vm --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

gsutil mb -p $DEVSHELL_PROJECT_ID -c STANDARD -l $REGION -b on gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

gsutil uniformbucketlevelaccess set off gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

curl -LO findings.jsonl

gsutil cp findings.jsonl gs://scc-export-bucket-$DEVSHELL_PROJECT_ID

echo "${CYAN}${BOLD}OPEN THIS LINK: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/security/web-scanner/scanConfigs/edit?project=$DEVSHELL_PROJECT_ID"""${RESET}"

echo "${YELLOW}${BOLD}COPY THIS: "${RESET}""${GREEN}${BOLD}""http://$VM_EXT_IP:8080"""${RESET}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}              NOW FOLLOW VIDEO STEPS...              ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}*******************************************************${RESET_FORMAT}"

# Completion Message
# echo
# echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo