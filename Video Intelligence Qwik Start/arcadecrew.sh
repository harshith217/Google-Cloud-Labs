#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_WHITE=$'\033[47m'
DIM_TEXT=$'\033[2m'
BLINK_TEXT=$'\033[5m'
REVERSE_TEXT=$'\033[7m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📋 STEP 1: Setting up IAM Service Account${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}🔧 We'll create a new service account for authentication purposes${RESET_FORMAT}"
echo
gcloud iam service-accounts create quickstart && \
echo "${GREEN_TEXT}✓ Service account created successfully${RESET}" || \
echo "${RED_TEXT}✗ Failed to create service account${RESET}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 STEP 2: Generating Service Account Credentials${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}📄 Creating JSON key file for service account authentication${RESET_FORMAT}"
echo
gcloud iam service-accounts keys create key.json \
    --iam-account quickstart@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com && \
echo "${GREEN_TEXT}✓ Service account key created successfully${RESET}" || \
echo "${RED_TEXT}✗ Failed to create service account key${RESET}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🎯 STEP 3: Activating Authentication Context${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}🔄 Switching to service account for API operations${RESET_FORMAT}"
echo
gcloud auth activate-service-account --key-file key.json && \
echo "${GREEN_TEXT}✓ Service account activated successfully${RESET}" || \
echo "${RED_TEXT}✗ Failed to activate service account${RESET}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🎫 STEP 4: Obtaining API Access Token${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}🔐 Retrieving bearer token for Video Intelligence API${RESET_FORMAT}"
echo
ACCESS_TOKEN=$(gcloud auth print-access-token)
echo "${CYAN}Access Token: ${WHITE}${ACCESS_TOKEN:0:20}...${RESET}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📝 STEP 5: Preparing Video Analysis Request${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}🎬 Configuring request for label detection on sample video${RESET_FORMAT}"
echo
cat > request.json <<EOF
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "LABEL_DETECTION"
   ]
}
EOF
echo "${GREEN_TEXT}✓ Request file created successfully${RESET}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 STEP 6: Submitting Video Intelligence Request${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}📡 Sending annotation request to Google Video Intelligence API${RESET_FORMAT}"
echo
response=$(curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json)

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}✓ Annotation request submitted successfully${RESET}"
else
    echo "${RED_TEXT}✗ Failed to submit annotation request${RESET}"
    exit 1
fi
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ STEP 7: Extracting Operation Metadata${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}📊 Parsing response to get operation tracking details${RESET_FORMAT}"
echo
project_id=$(echo $response | jq -r '.name' | cut -d'/' -f2)
location=$(echo $response | cut -d'/' -f4)
operation_name=$(echo $response | cut -d'/' -f6)

echo "${CYAN}Project ID: ${WHITE}$project_id${RESET}"
echo "${CYAN}Location: ${WHITE}$location${RESET}"
echo "${CYAN}Operation Name: ${WHITE}$operation_name${RESET}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📈 STEP 8: Monitoring Operation Status${RESET_FORMAT}"
echo "${WHITE_TEXT}${DIM_TEXT}🔎 Checking current status of video analysis operation${RESET_FORMAT}"
echo
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    "https://videointelligence.googleapis.com/v1/projects/$project_id/locations/$location/operations/$operation_name"

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}✓ Operation status retrieved successfully${RESET}"
else
    echo "${RED_TEXT}✗ Failed to retrieve operation status${RESET}"
fi

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
