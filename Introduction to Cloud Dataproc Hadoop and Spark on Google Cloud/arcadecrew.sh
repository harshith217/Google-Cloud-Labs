#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
MAGENTA_COLOR="\e[35m"
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter CLUSTER_NAME: ${RESET_FORMAT}" CLUSTER_NAME

# Export variables after collecting input
export CLUSTER_NAME 

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")


PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud dataproc clusters create $CLUSTER_NAME --project $DEVSHELL_PROJECT_ID --region $REGION --zone $ZONE --master-machine-type n1-standard-2 --worker-machine-type n1-standard-2 --worker-boot-disk-size 100GB --worker-boot-disk-type pd-standard --num-workers 2 --no-address

gcloud dataproc jobs submit spark \
    --project $DEVSHELL_PROJECT_ID \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --class org.apache.spark.examples.SparkPi \
    --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000


echo "Click this link to open" "${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/dataproc/jobs?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo
echo -e "\e[1;31mDeleting the script (arcadecrew.sh) for safety purposes...\e[0m"
rm -- "$0"
echo
echo
# Completion message
echo -e "${MAGENTA_COLOR}IF GETTING ${BOLD_TEXT}ERROR RERUN THE COMMANDS.${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
