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
cd ~
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

# Set environment variables
export PROJECT_ID="$(gcloud config get-value project -q)"

# Get the current date and time in UTC format: YYYY-MM-DD HH:MM:SS
CURRENT_DATETIME=$(date -u +"%Y-%m-%d %H:%M:%S")
echo "${MAGENTA_TEXT}${BOLD_TEXT}Current Date and Time (UTC): $CURRENT_DATETIME ${RESET_FORMAT}"

# Get the current user's login
CURRENT_USER=$(whoami)
echo "${MAGENTA_TEXT}${BOLD_TEXT}Current User's Login: $CURRENT_USER ${RESET_FORMAT}"

# Prompt user for their email address
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter USERNAME: ${RESET_FORMAT}"
read EMAIL

# Validate email format (basic check)
if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Invalid email format. Please run the script again with a valid email. ${RESET_FORMAT}"
fi

# Using a fixed display name for the policy as requested
export POLICY_NAME="CPU request utilization"
export DISPLAY_NAME="Email Alert for $POLICY_NAME"

echo "${GREEN_TEXT}${BOLD_TEXT}Creating alert policy named '$POLICY_NAME'... ${RESET_FORMAT}"

# First, create a notification channel for email
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up email notification channel... ${RESET_FORMAT}"
CHANNEL_ID=$(gcloud alpha monitoring channels create \
  --display-name="$DISPLAY_NAME" \
  --type=email \
  --channel-labels=email_address="$EMAIL" \
  --format="value(name)")

echo "${GREEN_TEXT}${BOLD_TEXT}Created notification channel: $CHANNEL_ID ${RESET_FORMAT}"

# Create the alert policy for CPU request utilization above 99%
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the alert policy... ${RESET_FORMAT}"
gcloud alpha monitoring policies create \
  --display-name="$POLICY_NAME" \
  --condition-display-name="$POLICY_NAME above threshold" \
  --condition-filter='resource.type = "k8s_container" AND metric.type = "kubernetes.io/container/cpu/request_utilization"' \
  --condition-threshold-value=0.99 \
  --condition-threshold-comparison=COMPARISON_GT \
  --condition-aggregations-per-series-aligner=ALIGN_MEAN \
  --condition-aggregations-alignment-period=60s \
  --notification-channels="$CHANNEL_ID"

# Check if the policy creation was successful
if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Alert policy '$POLICY_NAME' created successfully! ${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}Alert notifications will be sent to: $EMAIL ${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}Failed to create alert policy. Please check your permissions and try again. ${RESET_FORMAT}"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
