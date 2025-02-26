#!/bin/bash

# Bright Foreground Colors
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
BOLD_TEXT=$'\033[1m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

# Set project variables
echo "${BLUE_TEXT}${BOLD_TEXT}Setting up Google Cloud Project variables...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
ZONE=$(gcloud compute instances list --format="value(zone)" | head -n1) # Fetching zone dynamically
VM_INSTANCE="lab-vm" # Replace with actual VM name if different

if [[ -z "$PROJECT_ID" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: No project ID found. Set a Google Cloud project using 'gcloud config set project PROJECT_ID'.${RESET_FORMAT}"
    exit 1
fi

if [[ -z "$ZONE" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: No zone found. Ensure a VM is provisioned.${RESET_FORMAT}"
    exit 1
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Project ID: $PROJECT_ID${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Zone: $ZONE${RESET_FORMAT}"

# Task 1: Create an API Key
echo "${BLUE_TEXT}${BOLD_TEXT}Creating an API Key...${RESET_FORMAT}"
API_KEY=$(gcloud services api-keys create "nl-api-key" --display-name="Natural Language API Key" --format="value(keyString)")
if [[ -z "$API_KEY" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Failed to create an API key.${RESET_FORMAT}"
    exit 1
fi
echo "${GREEN_TEXT}${BOLD_TEXT}API Key Created: $API_KEY${RESET_FORMAT}"

# Enable required APIs
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling Cloud Natural Language API...${RESET_FORMAT}"
gcloud services enable language.googleapis.com

# Save API key to VM
echo "${BLUE_TEXT}${BOLD_TEXT}Saving API key on VM...${RESET_FORMAT}"
gcloud compute ssh "$VM_INSTANCE" --zone="$ZONE" --quiet --command "echo 'export API_KEY=$API_KEY' | sudo tee -a /etc/profile"

# Task 2 & 4: Run commands inside VM via SSH
echo "${BLUE_TEXT}${BOLD_TEXT}Executing commands inside the VM...${RESET_FORMAT}"

gcloud compute ssh "$VM_INSTANCE" --zone="$ZONE" --quiet --command "
    # Create analyze-request.json
    echo '{
      \"document\":{
        \"type\":\"PLAIN_TEXT\",
        \"content\": \"Google, headquartered in Mountain View, unveiled the new Android phone at the Consumer Electronic Show. Sundar Pichai said in his keynote that users love their new Android phones.\"
      },
      \"encodingType\": \"UTF8\"
    }' > analyze-request.json

    # Call Natural Language API and save response
    curl -s -X POST -H \"Content-Type: application/json\" -d @analyze-request.json \"https://language.googleapis.com/v1/documents:analyzeSyntax?key=$API_KEY\" > analyze-response.txt
    echo '${BOLD_TEXT}${GREEN_TEXT}✅ Syntax analysis saved in analyze-response.txt${RESET_FORMAT}'

    # Create multi-nl-request.json for French text
    echo '{
      \"document\":{
        \"type\":\"PLAIN_TEXT\",
        \"content\": \"Le bureau japonais de Google est situé à Roppongi Hills, Tokyo.\"
      }
    }' > multi-nl-request.json

    # Call Natural Language API for multilingual processing
    curl -s -X POST -H \"Content-Type: application/json\" -d @multi-nl-request.json \"https://language.googleapis.com/v1/documents:analyzeSyntax?key=$API_KEY\" > multi-response.txt
    echo '${GREEN_TEXT}${BOLD_TEXT}✅ Multilingual analysis saved in multi-response.txt${RESET_FORMAT}'
"
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo