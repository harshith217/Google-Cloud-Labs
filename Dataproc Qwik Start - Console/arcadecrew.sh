#!/bin/bash
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

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Determining the default Google Cloud zone...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Default zone set to: ${ZONE}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🌍 Determining the default Google Cloud region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Default region set to: ${REGION}${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔢 Fetching the project number for your GCP project...${RESET_FORMAT}"
export PROJECT_NUMBER="$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='get(projectNumber)')"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project number identified: ${PROJECT_NUMBER}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Granting Storage Object Admin role to the Compute Engine default service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/storage.objectAdmin
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Role 'roles/storage.objectAdmin' granted.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Granting Storage Admin role to the Compute Engine default service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/storage.admin
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Role 'roles/storage.admin' granted.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔐 Granting Dataproc Worker role to the Compute Engine default service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/dataproc.worker
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Role 'roles/dataproc.worker' granted.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting for IAM permissions to propagate...${RESET_FORMAT}"
sleep 30
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Permissions should now be active.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT} @ [${REGION}] ... ${RESET_FORMAT}"

# Check if the default network exists
if ! gcloud compute networks describe default --project "$DEVSHELL_PROJECT_ID" &>/dev/null; then
  echo "${YELLOW_TEXT}A Default network not found. Creating default network with auto-subnets ... ${RESET_FORMAT}"
  
  gcloud compute networks create default --subnet-mode=auto --project "$DEVSHELL_PROJECT_ID"
  
  if [[ $? -eq 0 ]]; then
    echo "${GREEN_TEXT}✔️ Default network created successfully.${RESET_FORMAT}"
    echo "${YELLOW_TEXT}Waiting a bit for network resources to propagate ...${RESET_FORMAT}"
    sleep 20 # Wait for network creation and subnet propagation
  else
    echo "${RED_TEXT}❌ Failed to create default network. Cluster creation might fail. Exiting.${RESET_FORMAT}"
    exit 1
  fi
else
  echo "${GREEN_TEXT}✔️ Default network found.${RESET_FORMAT}"
fi

# Network exists, verify subnetwork in the specific region
echo "${YELLOW_TEXT}Verifying default subnetwork in region ${REGION} ...${RESET_FORMAT}"
if ! gcloud compute networks subnets describe default --region "$REGION" --project "$DEVSHELL_PROJECT_ID" &>/dev/null; then
  echo "${RED_TEXT}❌ Default network exists, but default subnetwork in region ${REGION} is missing or not ready. Cluster creation might fail.${RESET_FORMAT}"
  echo "${YELLOW_TEXT}Waiting longer for potential propagation ...${RESET_FORMAT}"
  sleep 30
else
  echo "${GREEN_TEXT}✔️ Default subnetwork found in region ${REGION}.${RESET_FORMAT}"
fi

echo

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️ Creating a new Dataproc cluster named 'example-cluster'. This might take a few minutes...${RESET_FORMAT}"
gcloud dataproc clusters create example-cluster --region $REGION --zone $ZONE --master-machine-type e2-standard-2 --master-boot-disk-type pd-standard --master-boot-disk-size 30 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-standard --worker-boot-disk-size 30 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Dataproc cluster 'example-cluster' created successfully!${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Submitting a Spark job (SparkPi example) to the 'example-cluster'...${RESET_FORMAT}"
gcloud dataproc jobs submit spark \
  --cluster example-cluster \
  --region $REGION \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Spark job submitted successfully! Check the output for Pi estimation.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📈 Updating the 'example-cluster' to scale up the number of workers to 4...${RESET_FORMAT}"
gcloud dataproc clusters update example-cluster \
  --region $REGION \
  --num-workers 4
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cluster 'example-cluster' updated successfully to 4 workers!${RESET_FORMAT}"
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
