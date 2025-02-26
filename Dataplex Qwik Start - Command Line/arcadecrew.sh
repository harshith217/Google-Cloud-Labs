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

# Displaying start message
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Prompt user to enter the region
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -r REGION
echo "${GREEN_TEXT}Region set to: ${REGION}${RESET_FORMAT}"
export REGION

# Enabling required Google Cloud service
echo "${CYAN_TEXT}Enabling Dataplex API...${RESET_FORMAT}"
gcloud services enable dataplex.googleapis.com

# Setting project ID
echo "${MAGENTA_TEXT}Fetching Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}Project ID: ${PROJECT_ID}${RESET_FORMAT}"

# Configuring region
echo "${BLUE_TEXT}Setting compute region to ${REGION}...${RESET_FORMAT}"
gcloud config set compute/region $REGION

# Creating Dataplex Lake
echo "${YELLOW_TEXT}Creating Dataplex Lake: Ecommerce...${RESET_FORMAT}"
gcloud dataplex lakes create ecommerce \
   --location=$REGION \
   --display-name="Ecommerce" \
   --description="Ecommerce Domain"

# Creating Dataplex Zone
echo "${YELLOW_TEXT}Creating Orders Curated Zone...${RESET_FORMAT}"
gcloud dataplex zones create orders-curated-zone \
    --location=$REGION \
    --lake=ecommerce \
    --display-name="Orders Curated Zone" \
    --resource-location-type=SINGLE_REGION \
    --type=CURATED \
    --discovery-enabled \
    --discovery-schedule="0 * * * *"
    
# Creating BigQuery Dataset
echo "${CYAN_TEXT}Creating BigQuery dataset: orders...${RESET_FORMAT}"
bq mk --location=$REGION --dataset orders 

# Creating Dataplex Asset
echo "${MAGENTA_TEXT}Creating Dataplex Asset: Orders Curated Dataset...${RESET_FORMAT}"
gcloud dataplex assets create orders-curated-dataset \
--location=$REGION \
--lake=ecommerce \
--zone=orders-curated-zone \
--display-name="Orders Curated Dataset" \
--resource-type=BIGQUERY_DATASET \
--resource-name=projects/$PROJECT_ID/datasets/orders \
--discovery-enabled 

# Deleting Dataplex Asset
echo "${RED_TEXT}Deleting Dataplex Asset: Orders Curated Dataset...${RESET_FORMAT}"
gcloud dataplex assets delete orders-curated-dataset --location=$REGION --zone=orders-curated-zone --lake=ecommerce --quiet

# Deleting Dataplex Zone
echo "${RED_TEXT}Deleting Orders Curated Zone...${RESET_FORMAT}"
gcloud dataplex zones delete orders-curated-zone --location=$REGION --lake=ecommerce --quiet

# Deleting Dataplex Lake
echo "${RED_TEXT}Deleting Dataplex Lake: Ecommerce...${RESET_FORMAT}"
gcloud dataplex lakes delete ecommerce --location=$REGION --quiet

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