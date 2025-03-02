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

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Enter REGION: ${RESET_FORMAT}"
read -r REGION
export REGION=$REGION
echo "${BLUE_TEXT}${BOLD_TEXT} User selected region : $REGION ${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Disabling Dataflow API ========================== ${RESET_FORMAT}"
echo

gcloud services disable dataflow.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling Dataflow API ========================== ${RESET_FORMAT}"
echo
gcloud services enable dataflow.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating BigQuery Dataset ========================== ${RESET_FORMAT}"
echo

bq mk taxirides

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating BigQuery Table ========================== ${RESET_FORMAT}"
echo

bq mk \
--time_partitioning_field timestamp \
--schema ride_id:string,point_idx:integer,latitude:float,longitude:float,\
timestamp:timestamp,meter_reading:float,meter_increment:float,ride_status:string,\
passenger_count:integer -t taxirides.realtime

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating GCS Bucket ========================== ${RESET_FORMAT}"
echo

gsutil mb gs://$DEVSHELL_PROJECT_ID/

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Waiting for 45 seconds to finish GCS creation ========================== ${RESET_FORMAT}"
echo

sleep 45

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Running Dataflow Job ========================== ${RESET_FORMAT}"
echo

gcloud dataflow jobs run iotflow \
--gcs-location gs://dataflow-templates/latest/PubSub_to_BigQuery \
--region $REGION \
--staging-location gs://$DEVSHELL_PROJECT_ID/temp \
--parameters inputTopic=projects/pubsub-public-data/topics/taxirides-realtime,outputTableSpec=$DEVSHELL_PROJECT_ID:taxirides.realtime
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
