#!/bin/bash

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

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Prompt user to input three regions
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the ZONE: ${RESET_FORMAT}" ZONE
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the KEY_1: ${RESET_FORMAT}" KEY_1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the VALUE_1: ${RESET_FORMAT}" VALUE_1

export REGION="${ZONE%-*}"
ENTRY_GROUP_ID="custom_entry_group"

# TASK 1
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket in the specified region...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gsutil mb -p \$DEVSHELL_PROJECT_ID -l \$REGION -b on gs://\$DEVSHELL_PROJECT_ID-bucket/${RESET_FORMAT}"
gsutil mb -p $DEVSHELL_PROJECT_ID -l $REGION -b on gs://$DEVSHELL_PROJECT_ID-bucket/

# TASK 2
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Dataplex lake named 'customer-lake'...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud alpha dataplex lakes create customer-lake ...${RESET_FORMAT}"
gcloud alpha dataplex lakes create customer-lake \
--display-name="Customer-Lake" \
 --location=$REGION \
 --labels="key_1=$KEY_1,value_1=$VALUE_1"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Dataplex zone named 'public-zone'...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud dataplex zones create public-zone ...${RESET_FORMAT}"
gcloud dataplex zones create public-zone \
    --lake=customer-lake \
    --location=$REGION \
    --type=RAW \
    --resource-location-type=SINGLE_REGION \
    --display-name="Public-Zone"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Dataplex environment named 'dataplex-lake-env'...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud dataplex environments create dataplex-lake-env ...${RESET_FORMAT}"
gcloud dataplex environments create dataplex-lake-env \
           --project=$DEVSHELL_PROJECT_ID --location=$REGION --lake=customer-lake \
           --os-image-version=1.0 --compute-node-count 3  --compute-max-node-count 3 

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Data Catalog entry group named 'custom_entry_group'...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud data-catalog entry-groups create \$ENTRY_GROUP_ID ...${RESET_FORMAT}"
gcloud data-catalog entry-groups create $ENTRY_GROUP_ID \
    --location=$REGION \
    --display-name="Custom entry group"

# TASK 3
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Dataplex asset 'customer-raw-data' for raw data storage...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud dataplex assets create customer-raw-data ...${RESET_FORMAT}"
gcloud dataplex assets create customer-raw-data --location=$REGION \
            --lake=customer-lake --zone=public-zone \
            --resource-type=STORAGE_BUCKET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/buckets/$DEVSHELL_PROJECT_ID-customer-bucket \
            --discovery-enabled \
            --display-name="Customer Raw Data"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Dataplex asset 'customer-reference-data' for reference data...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud dataplex assets create customer-reference-data ...${RESET_FORMAT}"
gcloud dataplex assets create customer-reference-data --location=$REGION \
            --lake=customer-lake --zone=public-zone \
            --resource-type=BIGQUERY_DATASET \
            --resource-name=projects/$DEVSHELL_PROJECT_ID/datasets/customer_reference_data \
            --display-name="Customer Reference Data"

# TASK 4
# Uncomment and modify the following lines if needed for creating tag templates
# echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a Data Catalog tag template named 'customer_data_tag_template'...${RESET_FORMAT}"
# echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: gcloud data-catalog tag-templates create customer_data_tag_template ...${RESET_FORMAT}"
# gcloud data-catalog tag-templates create customer_data_tag_template \
#    --project=$DEVSHELL_PROJECT_ID \
#    --location=$REGION \
#    --display-name="Customer Data Tag Template"
#    --field=id=DataOwner,display-name=Data\ Owner,type=string,required=TRUE \
#    --field=id=PIIData,display-name=PII\ Data,type='enum(Yes|No)',required=TRUE

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
