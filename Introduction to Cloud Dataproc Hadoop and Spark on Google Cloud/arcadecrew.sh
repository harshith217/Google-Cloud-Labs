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

# Set Variables Dynamically
PROJECT_ID=$(gcloud config get-value project)
CLUSTER_NAME="dataproc-cluster"
REGION="us-central1"
ZONE="us-central1-a"
MASTER_MACHINE_TYPE="n1-standard-2"
WORKER_MACHINE_TYPE="n1-standard-2"
JOB_TYPE="pyspark"
MAIN_CLASS="org.apache.spark.examples.SparkPi"
JAR_FILE="file:///usr/lib/spark/examples/jars/spark-examples.jar"
ARGUMENTS="1000"

# Fetch Service Account
SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format='value(email)' | grep "compute@developer")

# Assign Storage Admin Role
printf "${BOLD_TEXT}${YELLOW_COLOR}Assigning Storage Admin role to service account...${NO_COLOR}\n"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/storage.admin" || { printf "${RED_TEXT}Failed to assign IAM role!${NO_COLOR}\n"; exit 1; }

# Create Cloud Dataproc Cluster
printf "${BOLD_TEXT}${MAGENTA_COLOR}Creating Dataproc Cluster...${NO_COLOR}\n"
gcloud dataproc clusters create $CLUSTER_NAME \
    --region=$REGION \
    --zone=$ZONE \
    --master-machine-type=$MASTER_MACHINE_TYPE \
    --worker-machine-type=$WORKER_MACHINE_TYPE \
    --num-workers=2 \
    --worker-boot-disk-size=100GB \
    --worker-boot-disk-type=pd-standard \
    --no-address || { printf "${RED_TEXT}Failed to create cluster!${NO_COLOR}\n"; exit 1; }

# Verify Cluster Creation
printf "${BOLD_TEXT}${GREEN_TEXT}Waiting for cluster to be ready...${NO_COLOR}\n"
sleep 10
gcloud dataproc clusters list --region=$REGION | grep $CLUSTER_NAME || { printf "${RED_TEXT}Cluster creation failed!${NO_COLOR}\n"; exit 1; }

# Submit Spark Job
printf "${BOLD_TEXT}${BLUE_TEXT}Submitting Spark job...${NO_COLOR}\n"
gcloud dataproc jobs submit $JOB_TYPE \
    --region=$REGION \
    --cluster=$CLUSTER_NAME \
    --class=$MAIN_CLASS \
    --jars=$JAR_FILE \
    -- $ARGUMENTS || { printf "${RED_TEXT}Job submission failed!${NO_COLOR}\n"; exit 1; }

# Verify Job Completion
printf "${BOLD_TEXT}${GREEN_TEXT}Waiting for job to complete...${NO_COLOR}\n"
sleep 10
gcloud dataproc jobs list --region=$REGION | grep Succeeded || { printf "${RED_TEXT}Job did not succeed!${NO_COLOR}\n"; exit 1; }

echo
# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_COLOR}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo