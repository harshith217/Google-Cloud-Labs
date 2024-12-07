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

read -p "Enter REGION: " REGION

export PROJECT_ID=$(gcloud config get-value project)

bq mk --connection --connection_type='CLOUD_SPANNER' --properties='{"database":"projects/'$PROJECT_ID'/instances/ecommerce-instance/databases/ecommerce"}' --project_id=$PROJECT_ID --location=$REGION my_connection_id

bq query --use_legacy_sql=false "SELECT * FROM EXTERNAL_QUERY('$PROJECT_ID.$REGION.my_connection_id', 'SELECT * FROM orders;');"

bq query --use_legacy_sql=false "CREATE VIEW ecommerce.order_history AS SELECT * FROM EXTERNAL_QUERY('$PROJECT_ID.$REGION.my_connection_id', 'SELECT * FROM orders;');"

echo ""
# Completion message
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

