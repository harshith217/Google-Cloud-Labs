#!/bin/bash
# Define text formatting variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Setting the default Compute Engine zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Zone set to: ${ZONE}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🌍 Setting the default Compute Engine region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Region set to: ${REGION}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔢 Fetching the project number...${RESET_FORMAT}"
export PROJECT_NUMBER="$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='get(projectNumber)')"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project Number: ${PROJECT_NUMBER}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Granting Storage Object Admin role to the Compute Engine service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/storage.objectAdmin
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Storage Object Admin role granted.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Granting Dataproc Worker role to the Compute Engine service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/dataproc.worker
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Dataproc Worker role granted.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Creating the Dataproc cluster 'example-cluster'. This might take a few minutes...${RESET_FORMAT}"
gcloud dataproc clusters create example-cluster --region $REGION --zone $ZONE --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 30 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 30 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Dataproc cluster 'example-cluster' created successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Submitting the SparkPi example job to the cluster...${RESET_FORMAT}"
gcloud dataproc jobs submit spark \
    --cluster example-cluster \
    --region $REGION \
    --class org.apache.spark.examples.SparkPi \
    --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000
echo "${GREEN_TEXT}${BOLD_TEXT}✅ SparkPi job submitted successfully! Check the output for Pi estimation.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📈 Updating the cluster 'example-cluster' to use 4 workers...${RESET_FORMAT}"
gcloud dataproc clusters update example-cluster \
    --region $REGION \
    --num-workers 4
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cluster 'example-cluster' updated to 4 workers.${RESET_FORMAT}"
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

