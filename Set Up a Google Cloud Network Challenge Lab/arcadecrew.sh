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

# Taking user input
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter VPC Network Name:${RESET_FORMAT}"
read NETWORK_NAME
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter First Subnet Name:${RESET_FORMAT}"
read SUBNET_A_NAME
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter Second Subnet Name:${RESET_FORMAT}"
read SUBNET_B_NAME
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter Firewall Rule 1 Name:${RESET_FORMAT}"
read FIREWALL_RULE1
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter Firewall Rule 2 Name:${RESET_FORMAT}"
read FIREWALL_RULE2
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter Firewall Rule 3 Name:${RESET_FORMAT}"
read FIREWALL_RULE3
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter First Zone:${RESET_FORMAT}"
read ZONE1
echo "${YELLOW_COLOR}${BOLD_TEXT}Enter Second Zone:${RESET_FORMAT}"
read ZONE2

# Extracting Regions from Zones
REGION1=$(gcloud compute zones describe $ZONE1 --format='value(region)')
REGION2=$(gcloud compute zones describe $ZONE2 --format='value(region)')

# Variables
PROJECT_ID=$(gcloud config get-value project)
INSTANCE1="us-test-01"
INSTANCE2="us-test-02"

# Function to check for errors
check_error() {
    if [ $? -ne 0 ]; then
        echo "${RED_TEXT}${BOLD_TEXT}Error: Something went wrong! Exiting.${RESET_FORMAT}"
        exit 1
    fi
}

# Step 1: Create VPC Network and Subnets
echo "${YELLOW_COLOR}${BOLD_TEXT}Creating VPC Network and Subnets...${RESET_FORMAT}"
gcloud compute networks create $NETWORK_NAME \
    --subnet-mode=custom --bgp-routing-mode=regional
check_error

gcloud compute networks subnets create $SUBNET_A_NAME \
    --network=$NETWORK_NAME --region=$REGION1 \
    --range=10.10.10.0/24 --stack-type=IPV4_ONLY
check_error

gcloud compute networks subnets create $SUBNET_B_NAME \
    --network=$NETWORK_NAME --region=$REGION2 \
    --range=10.10.20.0/24 --stack-type=IPV4_ONLY
check_error

# Step 2: Create Firewall Rules
echo "${MAGENTA_COLOR}${BOLD_TEXT}Creating Firewall Rules...${RESET_FORMAT}"
gcloud compute firewall-rules create $FIREWALL_RULE1 \
    --network=$NETWORK_NAME --priority=1000 --direction=INGRESS \
    --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0
check_error

gcloud compute firewall-rules create $FIREWALL_RULE2 \
    --network=$NETWORK_NAME --priority=65535 --direction=INGRESS \
    --action=ALLOW --rules=tcp:3389 --source-ranges=0.0.0.0/24
check_error

gcloud compute firewall-rules create $FIREWALL_RULE3 \
    --network=$NETWORK_NAME --priority=1000 --direction=INGRESS \
    --action=ALLOW --rules=icmp --source-ranges=10.10.10.0/24,10.10.20.0/24
check_error

# Step 3: Create VM Instances
echo "${BLUE_TEXT}${BOLD_TEXT}Creating Virtual Machines...${RESET_FORMAT}"
gcloud compute instances create $INSTANCE1 \
    --zone=$ZONE1 --machine-type=e2-micro --subnet=$SUBNET_A_NAME \
    --tags=allow-ssh,allow-icmp
check_error

gcloud compute instances create $INSTANCE2 \
    --zone=$ZONE2 --machine-type=e2-micro --subnet=$SUBNET_B_NAME \
    --tags=allow-ssh,allow-icmp
check_error

# Step 4: Verify Connection
echo "${GREEN_TEXT}${BOLD_TEXT}Verifying Connection Between Instances...${RESET_FORMAT}"
INSTANCE2_IP=$(gcloud compute instances describe $INSTANCE2 --zone=$ZONE2 --format='get(networkInterfaces[0].networkIP)')
check_error

gcloud compute ssh $INSTANCE1 --zone=$ZONE1 --command="ping -c 3 $INSTANCE2_IP"
check_error

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