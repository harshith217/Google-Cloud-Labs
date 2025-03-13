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

echo "${YELLOW_TEXT}${BOLD_TEXT}Executing BigQuery query to retrieve top 10 baby names...${RESET_FORMAT}"
echo
bq query --use_legacy_sql=false \
"
SELECT
name, gender,
SUM(number) AS total
FROM
\`bigquery-public-data.usa_names.usa_1910_2013\`
GROUP BY
name, gender
ORDER BY
total DESC
LIMIT
10
"

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating BigQuery dataset 'babynames'...${RESET_FORMAT}"
echo
bq mk babynames

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating BigQuery table 'names_2014'...${RESET_FORMAT}"
echo
bq mk --table \
--schema "name:string,count:integer,gender:string" \
$DEVSHELL_PROJECT_ID:babynames.names_2014

echo "${YELLOW_TEXT}${BOLD_TEXT}Loading data into BigQuery table 'names_2014'...${RESET_FORMAT}"
echo
bq query --use_legacy_sql=false \
"
SELECT
name, count
FROM
\`babynames.names_2014\`
WHERE
gender = 'M'
ORDER BY count DESC LIMIT 5
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
