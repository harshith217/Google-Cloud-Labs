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

echo "${GREEN_TEXT}${BOLD_TEXT}🗺️  Determining the default Google Cloud region for resource deployment...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${YELLOW_TEXT}${BOLD_TEXT}✅ Default region set to: ${REGION}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Enabling the Identity-Aware Proxy (IAP) API for secure access...${RESET_FORMAT}"
gcloud services enable iap.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}✅ IAP API enabled successfully.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️  Configuring gcloud to use the current project (${DEVSHELL_PROJECT_ID})...${RESET_FORMAT}"
gcloud config set project $DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project set successfully.${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📥 Cloning the official Google Cloud Python sample application repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Repository cloned.${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}📁 Changing directory to the 'hello_world' App Engine sample...${RESET_FORMAT}"
cd python-docs-samples/appengine/standard_python3/hello_world/
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Now in 'hello_world' directory.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🏗️  Creating a new App Engine application within the project and region...${RESET_FORMAT}"
gcloud app create --project=$(gcloud config get-value project) --region=$REGION
echo "${GREEN_TEXT}${BOLD_TEXT}✅ App Engine application created (or already exists).${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🚀 Deploying the 'hello_world' application to App Engine... (This might take a moment) ${RESET_FORMAT}"
gcloud app deploy --quiet
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Application deployed successfully.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🌐 Determining the authentication domain for the deployed application...${RESET_FORMAT}"
export AUTH_DOMAIN=$(gcloud config get-value project).uc.r.appspot.com
echo "${YELLOW_TEXT}${BOLD_TEXT}✅ Authentication domain set to: ${AUTH_DOMAIN}${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}👤 Fetching the developer's email address and preparing configuration details...${RESET_FORMAT}"
EMAIL="$(gcloud config get-value core/account)"

cat > details.json << EOF
  App name: arcadecrew
  Authorized domains: $AUTH_DOMAIN
  Developer contact email: $EMAIL
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}📄 Details saved in details.json:${RESET_FORMAT}"
cat details.json

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}👉 Next Step: Configure the OAuth consent screen using this link:${RESET_FORMAT}"
echo "${WHITE_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/apis/credentials/consent?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}👉 Then: Configure Identity-Aware Proxy (IAP) using this link:${RESET_FORMAT}"
echo "${WHITE_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/security/iap?tab=applications&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
