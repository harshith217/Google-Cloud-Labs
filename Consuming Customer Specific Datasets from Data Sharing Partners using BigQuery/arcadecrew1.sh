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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Add script description
echo "${CYAN_TEXT}${BOLD_TEXT}BIGQUERY DATA SHARING - CONSUMER SETUP${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter PUBLISHER_ID:${RESET_FORMAT}"
read PUBLISHER_ID

echo "${CYAN_TEXT}${BOLD_TEXT}Creating view to join customer data with publisher data...${RESET_FORMAT}"
echo "${GREEN_TEXT}This will create a view that combines your customer information with location data shared by the publisher.${RESET_FORMAT}"
echo

cat > view_b.py <<EOF_CP
from google.cloud import bigquery
client = bigquery.Client()
view_id = "$DEVSHELL_PROJECT_ID.customer_dataset.customer_table"
view = bigquery.Table(view_id)
view.view_query = f"SELECT cities.zip_code, cities.city, cities.state_code, customers.last_name, customers.first_name FROM \`$DEVSHELL_PROJECT_ID.customer_dataset.customer_info\` as customers JOIN \`$PUBLISHER_ID.data_publisher_dataset.authorized_view\` as cities ON cities.state_code = customers.state;"
view = client.create_table(view)

print(f"Created {view.table_type}: {str(view.reference)}")
EOF_CP

echo "${CYAN_TEXT}${BOLD_TEXT}Executing Python code to create the view...${RESET_FORMAT}"
echo

python3 view_b.py

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Note:${RESET_FORMAT} ${WHITE_TEXT}The view has been created successfully.${RESET_FORMAT}"
echo

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo