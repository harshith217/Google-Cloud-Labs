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

# Instruction for entering the shared ID
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter Shared ID:${RESET_FORMAT}"
read SHARED_ID

echo "${CYAN_TEXT}${BOLD_TEXT}Creating authorized view to access shared data...${RESET_FORMAT}"
echo "${GREEN_TEXT}This will create a view that filters records to only show New York (NY) state data.${RESET_FORMAT}"
echo

cat > view.py <<EOF_CP
from google.cloud import bigquery
client = bigquery.Client()
source_dataset_id = "data_publisher_dataset"
source_dataset_id_full = "{}.{}".format(client.project, source_dataset_id)
source_dataset = bigquery.Dataset(source_dataset_id_full)
view_id_a = "$DEVSHELL_PROJECT_ID.data_publisher_dataset.authorized_view"
view_a = bigquery.Table(view_id_a)
view_a.view_query = f"SELECT * FROM \`$SHARED_ID.demo_dataset.authorized_table\` WHERE state_code='NY' LIMIT 1000"
view_a = client.create_table(view_a)
access_entries = source_dataset.access_entries
access_entries.append(
bigquery.AccessEntry(None, "view", view_a.reference.to_api_repr())
)
source_dataset.access_entries = access_entries
source_dataset = client.update_dataset(
source_dataset, ["access_entries"]
)

print(f"Created {view_a.table_type}: {str(view_a.reference)}")
EOF_CP

echo "${CYAN_TEXT}${BOLD_TEXT}Executing Python code to create the authorized view...${RESET_FORMAT}"
echo

python3 view.py

sleep 3

echo "${YELLOW_TEXT}${BOLD_TEXT}Important:${RESET_FORMAT} ${CYAN_TEXT}Your Publisher ID is shown below. You'll need this ID for future reference.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}PUBLISHER ID : ${GREEN_TEXT}$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo "${CYAN_TEXT}Make note of this ID as it identifies your project as a data publisher.${RESET_FORMAT}"
echo

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo