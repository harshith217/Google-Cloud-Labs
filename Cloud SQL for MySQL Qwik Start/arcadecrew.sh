#!/bin/bash

# Bright Foreground Colors
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

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Setting up the environment ========================== ${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE: ${RESET_FORMAT}"
read -r ZONE
export ZONE=$ZONE
echo "${BLUE_TEXT}${BOLD_TEXT} You entered: $ZONE ${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Creating Cloud SQL Instance ========================== ${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud SQL instance 'myinstance' in region ${ZONE%-*} ... ${RESET_FORMAT}"

gcloud sql instances create myinstance \
  --root-password=awesome \
  --database-version=MYSQL_8_0 \
  --tier=db-n1-standard-4 \
  --region="${ZONE%-*}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Creating Database ========================== ${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating database 'guestbook' in 'myinstance' ... ${RESET_FORMAT}"
gcloud sql databases create guestbook --instance=myinstance

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
