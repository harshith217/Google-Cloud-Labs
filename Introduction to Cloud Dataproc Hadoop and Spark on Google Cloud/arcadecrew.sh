#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=$'\033[0;34m'

echo
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

# Fetching project region and zone
echo "${CYAN_TEXT}${BOLD_TEXT}Fetching project region and zone...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Fetching project ID
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Project ID...${RESET_FORMAT}"
PROJECT_ID=`gcloud config get-value project`

# Fetching project number
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Project Number...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")
echo "${MAGENTA_TEXT}Project Number: ${PROJECT_NUMBER}${RESET_FORMAT}"

# Granting Storage Admin role
echo "${BLUE_TEXT}${BOLD_TEXT}Granting Storage Admin role to service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

echo "${GREEN_TEXT}${BOLD_TEXT}Waiting for changes to take effect...${RESET_FORMAT}"
sleep 60

# Creating Dataproc cluster
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Dataproc cluster 'qlab'...${RESET_FORMAT}"
gcloud dataproc clusters create qlab --enable-component-gateway --region $REGION --zone $ZONE --master-machine-type e2-standard-4 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}Waiting for cluster creation...${RESET_FORMAT}"
sleep 120

# Deleting Dataproc cluster
echo "${RED_TEXT}${BOLD_TEXT}Deleting Dataproc cluster 'qlab'...${RESET_FORMAT}"
gcloud dataproc clusters delete qlab --region $REGION --quiet

echo "${CYAN_TEXT}${BOLD_TEXT}Recreating Dataproc cluster 'qlab'...${RESET_FORMAT}"
gcloud dataproc clusters create qlab --enable-component-gateway --region $REGION --zone $ZONE --master-machine-type e2-standard-4 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}Waiting for cluster to be ready...${RESET_FORMAT}"
sleep 120

# Submitting Spark job
echo "${YELLOW_TEXT}${BOLD_TEXT}Submitting Spark job to cluster...${RESET_FORMAT}"
gcloud dataproc jobs submit spark \
    --cluster=qlab \
    --region=$REGION \
    --class=org.apache.spark.examples.SparkPi \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo