#!/bin/bash

# Define color variables for output formatting
YELLOW_COLOR=$'\033[0;33m'
MAGENTA_COLOR="\e[35m"
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Cloud Skills Boost Lab Automation...${RESET_FORMAT}"
echo

# Set default values
read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter CLUSTER_NAME: ${RESET_FORMAT}" CLUSTER_NAME

# Export variables after collecting input
export CLUSTER_NAME
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
MASTER_MACHINE_TYPE="e2-standard-4"
WORKER_MACHINE_TYPE="e2-standard-2"
NUM_WORKERS=2
JOB_TYPE="spark"
MAIN_CLASS="org.apache.spark.examples.SparkPi"
JAR_FILE="file:///usr/lib/spark/examples/jars/spark-examples.jar"
ARGUMENTS=1000

# Export variables
export CLUSTER_NAME REGION ZONE MASTER_MACHINE_TYPE WORKER_MACHINE_TYPE NUM_WORKERS JOB_TYPE MAIN_CLASS JAR_FILE ARGUMENTS

# Authenticate and set project details
gcloud auth list

PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Ensure IAM permissions are set
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

# Create Dataproc cluster
echo -e "\e[1;34mCreating Dataproc cluster: $CLUSTER_NAME...\e[0m"
gcloud dataproc clusters create $CLUSTER_NAME \
    --project $PROJECT_ID \
    --region $REGION \
    --zone $ZONE \
    --master-machine-type $MASTER_MACHINE_TYPE \
    --worker-machine-type $WORKER_MACHINE_TYPE \
    --worker-boot-disk-size 100GB \
    --worker-boot-disk-type pd-standard \
    --num-workers $NUM_WORKERS \
    --no-address

# Wait for the cluster to be in RUNNING state
echo -e "\e[1;34mWaiting for the cluster to be in RUNNING state...\e[0m"
while true; do
    STATUS=$(gcloud dataproc clusters describe $CLUSTER_NAME --region $REGION --format="value(status.state)")
    if [[ "$STATUS" == "RUNNING" ]]; then
        echo -e "\e[1;32mCluster is now RUNNING!\e[0m"
        break
    else
        echo -e "\e[1;33mCurrent status: $STATUS. Retrying in 10 seconds...\e[0m"
        sleep 10
    fi
done

# Submit Spark job
echo -e "\e[1;34mSubmitting Spark job...\e[0m"
gcloud dataproc jobs submit $JOB_TYPE \
    --project $PROJECT_ID \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --class $MAIN_CLASS \
    --jars $JAR_FILE \
    -- $ARGUMENTS

echo -e "Click this link to open ${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/dataproc/jobs?project=$PROJECT_ID${RESET_FORMAT}"

echo -e "\e[1;31mDeleting the script (dataproc_lab.sh) for safety purposes...\e[0m"
rm -- "$0"

# Completion message
echo -e "${MAGENTA_COLOR}IF GETTING ${BOLD_TEXT}ERROR RERUN THE COMMANDS.${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe to our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
