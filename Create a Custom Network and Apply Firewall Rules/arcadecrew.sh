#!/bin/bash

# Bright Foreground Colors
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

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION1: ${RESET_FORMAT}" REGION1
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION2: ${RESET_FORMAT}" REGION2
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION3: ${RESET_FORMAT}" REGION3

# Export variables after collecting input
export REGION1 REGION2 REGION3

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Authenticating and Setting Configurations ========================== ${RESET_FORMAT}"
echo

gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone "$ZONE"
export ZONE=$(gcloud config get compute/zone)

gcloud config set compute/region "$REGION"
export REGION=$(gcloud config get compute/region)
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating Custom Network: taw-custom-network ========================== ${RESET_FORMAT}"
echo
gcloud compute networks create taw-custom-network --subnet-mode custom
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating Subnets in Different Regions ========================== ${RESET_FORMAT}"
echo

gcloud compute networks subnets create subnet-$REGION1 \
   --network taw-custom-network \
   --region $REGION1 \
   --range 10.0.0.0/16
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Subnet subnet-$REGION1 created in $REGION1 ========================== ${RESET_FORMAT}"
echo

gcloud compute networks subnets create subnet-$REGION2 \
   --network taw-custom-network \
   --region $REGION2 \
   --range 10.1.0.0/16
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Subnet subnet-$REGION2 created in $REGION2 ========================== ${RESET_FORMAT}"
echo

gcloud compute networks subnets create subnet-$REGION3 \
   --network taw-custom-network \
   --region $REGION3 \
   --range 10.2.0.0/16

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Subnet subnet-$REGION3 created in $REGION3 ========================== ${RESET_FORMAT}"
echo

gcloud compute networks subnets list \
   --network taw-custom-network

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating Firewall Rules ========================== ${RESET_FORMAT}"
echo

gcloud compute firewall-rules create nw101-allow-http \
--allow tcp:80 --network taw-custom-network --source-ranges 0.0.0.0/0 \
--target-tags http
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Firewall Rule: nw101-allow-http created ========================== ${RESET_FORMAT}"
echo

gcloud compute firewall-rules create "nw101-allow-icmp" --allow icmp --network "taw-custom-network" --target-tags rules
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Firewall Rule: nw101-allow-icmp created ========================== ${RESET_FORMAT}"
echo

gcloud compute firewall-rules create "nw101-allow-internal" --allow tcp:0-65535,udp:0-65535,icmp --network "taw-custom-network" --source-ranges "10.0.0.0/16","10.2.0.0/16","10.1.0.0/16"
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Firewall Rule: nw101-allow-internal created ========================== ${RESET_FORMAT}"
echo

gcloud compute firewall-rules create "nw101-allow-ssh" --allow tcp:22 --network "taw-custom-network" --target-tags "ssh"
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Firewall Rule: nw101-allow-ssh created ========================== ${RESET_FORMAT}"
echo
gcloud compute firewall-rules create "nw101-allow-rdp" --allow tcp:3389 --network "taw-custom-network"
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Firewall Rule: nw101-allow-rdp created ========================== ${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
