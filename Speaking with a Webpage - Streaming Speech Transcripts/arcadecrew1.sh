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
echo "${CYAN_TEXT}${BOLD_TEXT}Please enter the ZONE:${RESET_FORMAT}"
read ZONE

export ZONE

echo "${GREEN_TEXT}The zone is set to: $ZONE${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating a VM instance named 'speaking-with-a-webpage'...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}This may take a few moments.${RESET_FORMAT}"
echo

gcloud compute instances create speaking-with-a-webpage --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD  --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=speaking-with-a-webpage,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230711,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

sleep 20

echo
echo "${GREEN_TEXT}${BOLD_TEXT}VM instance created successfully!${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Setting up the VM with required software and configurations...${RESET_FORMAT}"
echo "${MAGENTA_TEXT}This may take a few minutes.${RESET_FORMAT}"
echo

gcloud compute ssh "speaking-with-a-webpage" --zone "$ZONE" --project "$DEVSHELL_PROJECT_ID" --quiet --command 'sudo apt update && sudo apt install git -y && sudo apt-get install -y maven openjdk-11-jdk && git clone https://github.com/googlecodelabs/speaking-with-a-webpage.git && gcloud compute firewall-rules create dev-ports --allow=tcp:8443 --source-ranges=0.0.0.0/0 && cd ~/speaking-with-a-webpage/01-hello-https && mvn clean jetty:run'

echo
echo "${RED_TEXT}${BOLD_TEXT}Important:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Run the NEXT Commands in a New CloudShell Tab.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Do not close this terminal until the setup is complete.${RESET_FORMAT}"
echo

echo