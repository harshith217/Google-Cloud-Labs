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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up the environment...${RESET_FORMAT}"
gcloud auth list

echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting the default project...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}${BOLD_TEXT}Your default region is: ${REGION}${RESET_FORMAT}"
echo

export GOOGLE_PROJECT=$DEVSHELL_PROJECT_ID
export CAI_BUCKET_NAME=cai-$GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID set to: ${GOOGLE_PROJECT}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}CAI Bucket Name set to: ${CAI_BUCKET_NAME}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling the Cloud Asset Inventory API...${RESET_FORMAT}"
gcloud services enable cloudasset.googleapis.com \
    --project $GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Asset Inventory API enabled successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a service identity for the Cloud Asset Inventory...${RESET_FORMAT}"
gcloud beta services identity create --service=cloudasset.googleapis.com --project=$GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}Service identity created successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy binding to grant storage admin role to the service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT}  \
   --member=serviceAccount:service-$(gcloud projects list --filter="$GOOGLE_PROJECT" --format="value(PROJECT_NUMBER)")@gcp-sa-cloudasset.iam.gserviceaccount.com \
   --role=roles/storage.admin
echo "${GREEN_TEXT}${BOLD_TEXT}IAM policy binding added successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the Forseti Policy Library repository...${RESET_FORMAT}"
git clone https://github.com/forseti-security/policy-library.git
echo "${GREEN_TEXT}${BOLD_TEXT}Forseti Policy Library cloned successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Copying the storage denylist public sample policy...${RESET_FORMAT}"
cp policy-library/samples/storage_denylist_public.yaml policy-library/policies/constraints/
echo "${GREEN_TEXT}${BOLD_TEXT}Storage denylist policy copied successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the Cloud Asset Inventory (CAI) bucket...${RESET_FORMAT}"
gsutil mb -l $REGION -p $GOOGLE_PROJECT gs://$CAI_BUCKET_NAME
echo "${GREEN_TEXT}${BOLD_TEXT}CAI bucket created successfully: gs://${CAI_BUCKET_NAME}${RESET_FORMAT}"
echo

# Export resource data
echo "${CYAN_TEXT}${BOLD_TEXT}Exporting resource data...${RESET_FORMAT}"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/resource_inventory.json \
    --content-type=resource \
    --project=$GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}Resource data exported successfully.${RESET_FORMAT}"

# Export IAM data
echo "${CYAN_TEXT}${BOLD_TEXT}Exporting IAM data...${RESET_FORMAT}"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/iam_inventory.json \
    --content-type=iam-policy \
    --project=$GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}IAM data exported successfully.${RESET_FORMAT}"

# Export org policy data
echo "${CYAN_TEXT}${BOLD_TEXT}Exporting organization policy data...${RESET_FORMAT}"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/org_policy_inventory.json \
    --content-type=org-policy \
    --project=$GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}Organization policy data exported successfully.${RESET_FORMAT}"

# Export access policy data
echo "${CYAN_TEXT}${BOLD_TEXT}Exporting access policy data...${RESET_FORMAT}"
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/access_policy_inventory.json \
    --content-type=access-policy \
    --project=$GOOGLE_PROJECT
echo "${GREEN_TEXT}${BOLD_TEXT}Access policy data exported successfully.${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
