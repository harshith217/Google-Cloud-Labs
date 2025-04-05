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

echo "${GREEN_TEXT}${BOLD_TEXT}Fetching the region...${RESET_FORMAT}"
export REGION=$(gcloud container clusters list --format='value(LOCATION)')

# Instruction for cluster credentials
echo "${MAGENTA_TEXT}${BOLD_TEXT}Fetching credentials for the Kubernetes cluster...${RESET_FORMAT}"
echo

gcloud container clusters get-credentials day2-ops --region $REGION

# Instruction for cloning the repository
echo "${GREEN_TEXT}${BOLD_TEXT}Cloning the microservices demo repository...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take a few moments.${RESET_FORMAT}"
echo

git clone https://github.com/GoogleCloudPlatform/microservices-demo.git

cd microservices-demo

# Instruction for deploying Kubernetes manifests
echo "${YELLOW_TEXT}${BOLD_TEXT}Applying Kubernetes manifests to deploy the application...${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Please wait while the resources are being created.${RESET_FORMAT}"
echo

kubectl apply -f release/kubernetes-manifests.yaml

sleep 60

# Instruction for retrieving the external IP
echo "${MAGENTA_TEXT}${BOLD_TEXT}Retrieving the external IP of the frontend service...${RESET_FORMAT}"
echo

export EXTERNAL_IP=$(kubectl get service frontend-external -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
echo $EXTERNAL_IP

# Instruction for testing the application
echo "${GREEN_TEXT}${BOLD_TEXT}Testing the application using curl...${RESET_FORMAT}"
echo

curl -o /dev/null -s -w "%{http_code}\n"  http://${EXTERNAL_IP}

# Instruction for enabling analytics
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling analytics for the default logging bucket...${RESET_FORMAT}"
echo

gcloud logging buckets update _Default \
    --location=global \
    --enable-analytics

# Instruction for creating a logging sink
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a logging sink for Kubernetes container logs...${RESET_FORMAT}"
echo

gcloud logging sinks create day2ops-sink \
    logging.googleapis.com/projects/$DEVSHELL_PROJECT_ID/locations/global/buckets/day2ops-log \
    --log-filter='resource.type="k8s_container"' \
    --include-children \
    --format='json'

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo