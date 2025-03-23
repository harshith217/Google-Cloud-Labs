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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -p "Region: " LOCATION
echo "${CYAN_TEXT}${BOLD_TEXT}You have selected: $LOCATION${RESET_FORMAT}"

gcloud services enable pubsub.googleapis.com
gcloud services enable run.googleapis.com

gcloud config set compute/region $LOCATION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Deploying Store Service...${RESET_FORMAT}"
gcloud run deploy store-service \
  --image gcr.io/qwiklabs-resources/gsp724-store-service \
  --region $LOCATION \
  --allow-unauthenticated

echo "${MAGENTA_TEXT}${BOLD_TEXT}Deploying Order Service...${RESET_FORMAT}"
gcloud run deploy order-service \
  --image gcr.io/qwiklabs-resources/gsp724-order-service \
  --region $LOCATION \
  --no-allow-unauthenticated

echo "${GREEN_TEXT}${BOLD_TEXT}Creating Pub/Sub topic ORDER_PLACED...${RESET_FORMAT}"
gcloud pubsub topics create ORDER_PLACED

echo "${GREEN_TEXT}${BOLD_TEXT}Creating Service Account for Pub/Sub...${RESET_FORMAT}"
gcloud iam service-accounts create pubsub-cloud-run-invoker \
  --display-name "Order Initiator"

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching Order Service URL...${RESET_FORMAT}"
export ORDER_SERVICE_URL=$(gcloud run services describe order-service \
   --region $LOCATION \
   --format="value(status.address.url)")

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Pub/Sub Subscription...${RESET_FORMAT}"
gcloud pubsub subscriptions create order-service-sub \
   --topic ORDER_PLACED \
   --push-endpoint=$ORDER_SERVICE_URL \
   --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo