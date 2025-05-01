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
echo "${YELLOW_TEXT}${BOLD_TEXT}📋 Preparing the environment...${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Setting the Project ID environment variable...${RESET_FORMAT}"
export PROJECT_ID="$(gcloud config get-value core/project)"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project ID set to: ${PROJECT_ID}${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📥 Copying necessary notebook files from the lab config bucket...${RESET_FORMAT}"
gsutil cp gs://$PROJECT_ID-labconfig-bucket/notebooks/*.ipynb .
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Notebooks copied successfully.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🐍 Installing required Python packages...${RESET_FORMAT}"
python -m pip install --upgrade google-cloud-core google-cloud-documentai google-cloud-storage prettytable
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Python packages installed/updated.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Copying the health intake form PDF...${RESET_FORMAT}"
gsutil cp gs://$PROJECT_ID-labconfig-bucket/health-intake-form.pdf form.pdf
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Health intake form copied as form.pdf.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}⚙️  Setting up the bucket name variable for Document AI...${RESET_FORMAT}"
export BUCKET="${PROJECT_ID}"_doc_ai_async
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Bucket name set to: ${BUCKET}${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🏗️  Creating a new Google Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://${BUCKET}
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Bucket gs://${BUCKET} created.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📤 Copying asynchronous processing files to the new bucket...${RESET_FORMAT}"
gsutil -m cp gs://$PROJECT_ID-labconfig-bucket/async/*.* gs://${BUCKET}/input
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Files copied to gs://${BUCKET}/input.${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥      NOW FOLLOW VIDEO STEPS     🎥${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
