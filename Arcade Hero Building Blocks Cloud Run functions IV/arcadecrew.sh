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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🛠️  Preparing Environment Variables...${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Fetching your Google Cloud Project ID... 🆔${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${YELLOW_TEXT}Project ID set to: ${BOLD_TEXT}${PROJECT_ID}${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Setting the deployment region... 🌍${RESET_FORMAT}"
echo "${WHITE_TEXT}We'll use '${BOLD_TEXT}us-central1${WHITE_TEXT}' as the region for our Cloud Function.${RESET_FORMAT}"
export REGION="us-central1"
echo "${YELLOW_TEXT}Region set to: ${BOLD_TEXT}${REGION}${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Defining the Cloud Function name... 📛${RESET_FORMAT}"
echo "${WHITE_TEXT}Our function will be named '${BOLD_TEXT}cf-nodejs${WHITE_TEXT}'.${RESET_FORMAT}"
export FUNCTION_NAME="cf-nodejs"
echo "${YELLOW_TEXT}Function name set to: ${BOLD_TEXT}${FUNCTION_NAME}${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}📝  Generating Source Code for the Cloud Function...${RESET_FORMAT}"
echo "${WHITE_TEXT}Next, we'll create the necessary files for our Node.js Cloud Function.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating a directory for the function source... 📁${RESET_FORMAT}"
echo "${WHITE_TEXT}A directory named '${BOLD_TEXT}cloud-function${WHITE_TEXT}' will be created to hold the function's code.${RESET_FORMAT}"
mkdir -p cloud-function

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Writing the Node.js function (index.js)... 📜${RESET_FORMAT}"
echo "${WHITE_TEXT}This creates a simple 'Hello World' function in '${BOLD_TEXT}cloud-function/index.js${WHITE_TEXT}'.${RESET_FORMAT}"
cat > cloud-function/index.js <<EOF
exports.helloWorld = (req, res) => {
  res.send('Hello from Cloud Function!');
};
EOF

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Creating the package.json file... 📦${RESET_FORMAT}"
echo "${WHITE_TEXT}This file defines the project dependencies and metadata in '${BOLD_TEXT}cloud-function/package.json${WHITE_TEXT}'.${RESET_FORMAT}"
cat > cloud-function/package.json <<EOF
{
  "name": "cf-nodejs",
  "version": "1.0.0",
  "main": "index.js"
}
EOF

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀  Deploying the Cloud Function to Google Cloud...${RESET_FORMAT}"
echo "${WHITE_TEXT}Now, we will deploy the function named '${BOLD_TEXT}${FUNCTION_NAME}${WHITE_TEXT}' using the gcloud command.${RESET_FORMAT}"
echo "${WHITE_TEXT}This deployment process might take a few minutes. Please be patient! 🙏${RESET_FORMAT}"
gcloud functions deploy ${FUNCTION_NAME} \
  --gen2 \
  --runtime=nodejs20 \
  --region=${REGION} \
  --source=cloud-function \
  --entry-point=helloWorld \
  --trigger-http \
  --max-instances=5 \
  --allow-unauthenticated

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

