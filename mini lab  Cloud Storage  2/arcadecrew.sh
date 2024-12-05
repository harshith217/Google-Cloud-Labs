#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"
echo ""

# Fetch the current Google Cloud project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

# Derive the bucket name based on the project ID
BUCKET_NAME="${PROJECT_ID}-bucket"

echo -e "\033[1;33mUsing bucket name: $BUCKET_NAME\033[0m"

# Define the lifecycle policy JSON
cat <<EOL > lifecycle.json
{
  "rule": [
    {
      "condition": {
        "age": 7,
        "matchesPrefix": ["processing/temp_logs/"]
      },
      "action": {
        "type": "Delete"
      }
    },
    {
      "condition": {
        "age": 90,
        "matchesPrefix": ["archive/"]
      },
      "action": {
        "type": "SetStorageClass",
        "storageClass": "NEARLINE"
      }
    },
    {
      "condition": {
        "age": 180,
        "matchesPrefix": ["archive/"]
      },
      "action": {
        "type": "SetStorageClass",
        "storageClass": "COLDLINE"
      }
    },
    {
      "condition": {
        "age": 30,
        "matchesPrefix": ["projects/active/"]
      },
      "action": {
        "type": "SetStorageClass",
        "storageClass": "STANDARD"
      }
    }
  ]
}
EOL

# Apply the lifecycle policy to the bucket
gsutil lifecycle set lifecycle.json gs://$BUCKET_NAME

# Clean up lifecycle.json
rm lifecycle.json

echo "Lifecycle management policy applied successfully to bucket: $BUCKET_NAME"

echo ""
# Completion message
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

