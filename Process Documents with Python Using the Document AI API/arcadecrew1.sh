#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}✨ Setting up environment variables...${RESET_FORMAT}"
export PROCESSOR_NAME=form-parser
export PROCESSOR_NAME_2=ocr-processor
export PROJECT_ID=$(gcloud config get-value core/project)
echo "${GREEN_TEXT}✅ Environment variables set.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Enabling necessary Google Cloud services... This might take a moment.${RESET_FORMAT}"
gcloud services enable documentai.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable geocoding-backend.googleapis.com
gcloud services enable eventarc.googleapis.com
gcloud services enable run.googleapis.com
echo "${GREEN_TEXT}✅ Services enabled successfully.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Retrieving access token for authentication...${RESET_FORMAT}"
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)
echo "${GREEN_TEXT}🔑 Access token retrieved.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Creating the first Document AI processor (Form Parser)...${RESET_FORMAT}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"
echo "${GREEN_TEXT}✅ First processor creation request sent.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📄 Creating the second Document AI processor (OCR Processor)...${RESET_FORMAT}"
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME_2"'",
    "type": "OCR_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"
echo "${GREEN_TEXT}✅ Second processor creation request sent.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Initializing processors...${RESET_FORMAT}"
for i in {30..1}; do
  printf "\r${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting: %2d seconds remaining... ${RESET_FORMAT}" $i
  sleep 1
done
printf "\r${GREEN_TEXT}✅ Initialization complete.           \n${RESET_FORMAT}"
echo 

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Fetching the Processor IDs...${RESET_FORMAT}"
export PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://us-documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')

echo "${GREEN_TEXT}${BOLD_TEXT}🆔 Processor IDs retrieved:${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Async ⤵️ ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}$PROCESSOR_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Sync ⤴️ ${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 OPEN VERTEX AI WORKBENCH FROM THIS LINK: ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/vertex-ai/workbench?project=$PROJECT_ID${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎬        NOW FOLLOW VIDEO STEPS        🎬${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
