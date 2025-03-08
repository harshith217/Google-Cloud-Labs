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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE: ${RESET_FORMAT}" my_zone

# Set environment variables
export my_cluster="standard-cluster-1"
export PROJECT_ID="$(gcloud config get-value project -q)"

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}Creating GKE cluster in zone: $my_zone...${RESET_FORMAT}"
gcloud container clusters create $my_cluster \
   --num-nodes 3 --enable-ip-alias --zone $my_zone  \
   --logging=SYSTEM \
   --monitoring=SYSTEM

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}Configuring kubectl access...${RESET_FORMAT}"
gcloud container clusters get-credentials $my_cluster --zone $my_zone

echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the lab repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/training-data-analyst

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a shortcut to the working directory...${RESET_FORMAT}"
ln -s ~/training-data-analyst/courses/ak8s/v1.1 ~/ak8s

echo "${BLUE_TEXT}${BOLD_TEXT}Changing to the Monitoring directory...${RESET_FORMAT}"
cd ~/ak8s/Monitoring/

echo ""
echo "${GREEN_TEXT}${BOLD_TEXT}Deploying the sample workload...${RESET_FORMAT}"
kubectl create -f hello-v2.yaml

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}Verifying the deployment...${RESET_FORMAT}"
kubectl get deployments

# Deploy the GCP-GKE-Monitor-Test application
echo ""
echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying the GCP-GKE-Monitor-Test application...${RESET_FORMAT}"
cd ~/ak8s/Monitoring/
git clone https://github.com/GoogleCloudPlatform/gcp-gke-monitor-test
cd gcp-gke-monitor-test

echo "${GREEN_TEXT}${BOLD_TEXT}Building and pushing the Docker image...${RESET_FORMAT}"
gcloud builds submit --tag=gcr.io/$PROJECT_ID/gcp-gke-monitor-test .

echo "${CYAN_TEXT}${BOLD_TEXT}Updating the deployment manifest with the correct image reference...${RESET_FORMAT}"
sed -i "s/\[DOCKER-IMAGE\]/gcr\.io\/${PROJECT_ID}\/gcp-gke-monitor-test\:latest/" gcp-gke-monitor-test.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}Deploying the application...${RESET_FORMAT}"
kubectl create -f gcp-gke-monitor-test.yaml

echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}Verifying the deployments and services...${RESET_FORMAT}"
kubectl get deployments
kubectl get service

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
