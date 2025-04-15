#!/bin/bash

# Define text colors and formatting
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
clear # Clear the terminal screen

# --- Script Header ---
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}         STARTING EXECUTION...       ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction before enabling the Document AI API
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${GREEN_TEXT}Enabling the Document AI API. This is required to use Document AI services.${RESET_FORMAT}"
gcloud services enable documentai.googleapis.com

# Instruction before setting the zone
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${GREEN_TEXT}Fetching the zone of the 'document-ai-dev' instance. Ensure the instance exists.${RESET_FORMAT}"
export ZONE=$(gcloud compute instances list document-ai-dev --format 'csv[no-heading](zone)')

# Instruction before SSH
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Connecting to the 'document-ai-dev' instance via SSH. This might take a few moments.${RESET_FORMAT}"
gcloud compute ssh document-ai-dev --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}***************************************${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}        NOW FOLLOW VIDEO STEPS         ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}***************************************${RESET_FORMAT}"
echo

# Instruction for navigating to the Document AI Console
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${GREEN_TEXT}Navigate to the Document AI Console to create a processor.${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Go to Document AI Console:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/ai/document-ai?project=${DEVSHELL_PROJECT_ID}${RESET_FORMAT}"
echo

# Instruction for entering the processor name
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${GREEN_TEXT}Enter the processor name as instructed in the video.${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Enter Processor Name as ${CYAN_TEXT} form-parser ${RESET_FORMAT}"
echo

# Instruction for confirming video steps
echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${GREEN_TEXT}Confirm if you have followed the video steps.${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Have you followed the video steps? (y/n):${RESET_FORMAT}"
read -r answer
if [[ $answer == "y" || $answer == "Y" ]]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Great! You can now proceed with the next steps.${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}Please follow the video steps before proceeding.${RESET_FORMAT}"
fi

# Instruction for entering the Processor ID
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${GREEN_TEXT}Enter your Processor ID. This is required for further processing.${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Please enter your Processor ID:${RESET_FORMAT}"
read -r PROCESSOR_ID
export PROCESSOR_ID

# Instruction before updating and installing dependencies
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} ${GREEN_TEXT}Updating the system and installing required dependencies.${RESET_FORMAT}"
sudo apt-get update
sudo apt-get install jq -y
sudo apt-get install python3-pip -y

# Instruction before creating a service account
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} ${GREEN_TEXT}Creating a service account for Document AI and setting up permissions.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
export SA_NAME="document-ai-service-account"
gcloud iam service-accounts create $SA_NAME --display-name $SA_NAME

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member="serviceAccount:$SA_NAME@${PROJECT_ID}.iam.gserviceaccount.com" \
--role="roles/documentai.apiUser"

gcloud iam service-accounts keys create key.json \
--iam-account  $SA_NAME@${PROJECT_ID}.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="$PWD/key.json"

# Instruction before downloading the sample PDF
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 10:${RESET_FORMAT} ${GREEN_TEXT}Downloading the sample PDF file for processing.${RESET_FORMAT}"
gsutil cp gs://cloud-training/gsp924/health-intake-form.pdf .

# Instruction before creating the JSON request
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 11:${RESET_FORMAT} ${GREEN_TEXT}Preparing the JSON request for Document AI API.${RESET_FORMAT}"
echo '{"inlineDocument": {"mimeType": "application/pdf","content": "' > temp.json
base64 health-intake-form.pdf >> temp.json
echo '"}}' >> temp.json
cat temp.json | tr -d \\n > request.json

# Instruction before sending the API request
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 12:${RESET_FORMAT} ${GREEN_TEXT}Sending the request to the Document AI API. This might take some time.${RESET_FORMAT}"
sleep 60
export LOCATION="us"
export PROJECT_ID=$(gcloud config get-value core/project)
curl -X POST \
-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @request.json \
https://${LOCATION}-documentai.googleapis.com/v1beta3/projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}:process > output.json

# Instruction before displaying the output
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 13:${RESET_FORMAT} ${GREEN_TEXT}Displaying the processed document text.${RESET_FORMAT}"
sleep 60
cat output.json | jq -r ".document.text"

# Instruction before downloading the Python script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 14:${RESET_FORMAT} ${GREEN_TEXT}Downloading the Python script for synchronous processing.${RESET_FORMAT}"
gsutil cp gs://cloud-training/gsp924/synchronous_doc_ai.py .

# Instruction before installing Python dependencies
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 15:${RESET_FORMAT} ${GREEN_TEXT}Installing Python dependencies for the script.${RESET_FORMAT}"
python3 -m pip install --upgrade google-cloud-documentai google-cloud-storage prettytable

# Instruction before running the Python script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 16:${RESET_FORMAT} ${GREEN_TEXT}Running the Python script for synchronous processing.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value core/project)
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/key.json"

python3 synchronous_doc_ai.py \
--project_id=$PROJECT_ID \
--processor_id=$PROCESSOR_ID \
--location=us \
--file_name=health-intake-form.pdf | tee results.txt

# Instruction before sending another API request
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 17:${RESET_FORMAT} ${GREEN_TEXT}Sending another request to the Document AI API for verification.${RESET_FORMAT}"
export LOCATION="us"
export PROJECT_ID=$(gcloud config get-value core/project)
curl -X POST \
-H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @request.json \
https://${LOCATION}-documentai.googleapis.com/v1beta3/projects/${PROJECT_ID}/locations/${LOCATION}/processors/${PROCESSOR_ID}:process > output.json

# Final message
echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo