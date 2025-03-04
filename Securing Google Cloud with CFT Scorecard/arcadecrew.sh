#!/bin/bash

# Bright Foreground Colors
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

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
export REGION
echo "${BLUE_TEXT}${BOLD_TEXT}REGION set to $REGION ${RESET_FORMAT}"
echo

export GOOGLE_PROJECT=$DEVSHELL_PROJECT_ID
export CAI_BUCKET_NAME=cai-$GOOGLE_PROJECT

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Enabling Cloud Asset Inventory API  ========================== ${RESET_FORMAT}"
echo

gcloud services enable cloudasset.googleapis.com \
    --project $GOOGLE_PROJECT

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Creating Cloud Asset Inventory Service Identity  ========================== ${RESET_FORMAT}"
echo

gcloud beta services identity create --service=cloudasset.googleapis.com --project=$GOOGLE_PROJECT

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} ==========================  Waiting for 60 Seconds for Service Identity Propagation  ========================== ${RESET_FORMAT}"
sleep 60

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Granting Storage Admin Role to CAI Service Account  ========================== ${RESET_FORMAT}"

gcloud projects add-iam-policy-binding ${GOOGLE_PROJECT}  \
   --member=serviceAccount:service-$(gcloud projects list --filter="$GOOGLE_PROJECT" --format="value(PROJECT_NUMBER)")@gcp-sa-cloudasset.iam.gserviceaccount.com \
   --role=roles/storage.admin

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Cloning Policy Library Repository  ========================== ${RESET_FORMAT}"

git clone https://github.com/forseti-security/policy-library.git

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Copying Storage Denylist Policy  ========================== ${RESET_FORMAT}"

cp policy-library/samples/storage_denylist_public.yaml policy-library/policies/constraints/

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Creating Storage Bucket ========================== ${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a new storage bucket in the specified region: ${REGION}${RESET_FORMAT}"

gsutil mb -l $REGION -p $GOOGLE_PROJECT gs://$CAI_BUCKET_NAME

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Exporting Resource Inventory Data  ========================== ${RESET_FORMAT}"
# Export resource data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/resource_inventory.json \
    --content-type=resource \
    --project=$GOOGLE_PROJECT

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Exporting IAM Inventory Data  ========================== ${RESET_FORMAT}"
# Export IAM data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/iam_inventory.json \
    --content-type=iam-policy \
    --project=$GOOGLE_PROJECT

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Exporting Org Policy Inventory Data  ========================== ${RESET_FORMAT}"
# Export org policy data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/org_policy_inventory.json \
    --content-type=org-policy \
    --project=$GOOGLE_PROJECT

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ==========================  Exporting Access Policy Inventory Data  ========================== ${RESET_FORMAT}"

# Export access policy data
gcloud asset export \
    --output-path=gs://$CAI_BUCKET_NAME/access_policy_inventory.json \
    --content-type=access-policy \
    --project=$GOOGLE_PROJECT

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
