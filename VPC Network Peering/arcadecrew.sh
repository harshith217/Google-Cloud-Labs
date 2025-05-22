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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Project ID 2: ${RESET_FORMAT}" PROJECT_ID_2
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 1 (Project A): ${RESET_FORMAT}" ZONE
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Zone 2 (Project B): ${RESET_FORMAT}" ZONE_2
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Setting Project ID 1 from your Google Cloud Shell environment variable (\$DEVSHELL_PROJECT_ID)...${RESET_FORMAT}"
export PROJECT_ID=$DEVSHELL_PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Extracting Region 1 from the provided Zone 1 (${WHITE_TEXT}${ZONE}${GREEN_TEXT})...${RESET_FORMAT}"
export REGION_1="${ZONE%-*}"

echo "${GREEN_TEXT}${BOLD_TEXT}🔧 Extracting Region 2 from the provided Zone 2 (${WHITE_TEXT}${ZONE_2}${GREEN_TEXT})...${RESET_FORMAT}"
export REGION_2="${ZONE_2%-*}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️ Configuring gcloud to use Project ID 1: ${WHITE_TEXT}${PROJECT_ID}${RESET_FORMAT}"
gcloud config set project $PROJECT_ID

echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Creating VPC network 'network-a' in Project ID 1 (${WHITE_TEXT}${PROJECT_ID}${CYAN_TEXT}) with custom subnet mode...${RESET_FORMAT}"
gcloud compute networks create network-a --subnet-mode custom

echo "${CYAN_TEXT}${BOLD_TEXT} subnet 'network-a-subnet' (10.0.0.0/16) in region ${WHITE_TEXT}${REGION_1}${CYAN_TEXT} for 'network-a'...${RESET_FORMAT}"
gcloud compute networks subnets create network-a-subnet --network network-a \
  --range 10.0.0.0/16 --region $REGION_1

echo "${CYAN_TEXT}${BOLD_TEXT}💻 Creating VM instance 'vm-a' in zone ${WHITE_TEXT}${ZONE}${CYAN_TEXT}, network 'network-a', subnet 'network-a-subnet'...${RESET_FORMAT}"
gcloud compute instances create vm-a --zone $ZONE --network network-a --subnet network-a-subnet --machine-type e2-small

echo "${CYAN_TEXT}${BOLD_TEXT}🛡️ Creating firewall rule 'network-a-fw' for 'network-a' to allow SSH (tcp:22) and ICMP...${RESET_FORMAT}"
gcloud compute firewall-rules create network-a-fw --network network-a --allow tcp:22,icmp
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️ Switching gcloud configuration to Project ID 2: ${WHITE_TEXT}${PROJECT_ID_2}${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_2

echo "${BLUE_TEXT}${BOLD_TEXT}🌐 Creating VPC network 'network-b' in Project ID 2 (${WHITE_TEXT}${PROJECT_ID_2}${BLUE_TEXT}) with custom subnet mode...${RESET_FORMAT}"
gcloud compute networks create network-b --subnet-mode custom

echo "${BLUE_TEXT}${BOLD_TEXT} subnet 'network-b-subnet' (10.8.0.0/16) in region ${WHITE_TEXT}${REGION_2}${BLUE_TEXT} for 'network-b'...${RESET_FORMAT}"
gcloud compute networks subnets create network-b-subnet --network network-b \
  --range 10.8.0.0/16 --region $REGION_2

echo "${BLUE_TEXT}${BOLD_TEXT}💻 Creating VM instance 'vm-b' in zone ${WHITE_TEXT}${ZONE_2}${BLUE_TEXT}, network 'network-b', subnet 'network-b-subnet'...${RESET_FORMAT}"
gcloud compute instances create vm-b --zone $ZONE_2 --network network-b --subnet network-b-subnet --machine-type e2-small

echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Creating firewall rule 'network-b-fw' for 'network-b' to allow SSH (tcp:22) and ICMP...${RESET_FORMAT}"
gcloud compute firewall-rules create network-b-fw --network network-b --allow tcp:22,icmp
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️ Switching gcloud configuration back to Project ID 1: ${WHITE_TEXT}${PROJECT_ID}${RESET_FORMAT}"
gcloud config set project $PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Creating network peering 'peer-ab' from 'network-a' (Project ID: ${WHITE_TEXT}${PROJECT_ID}${GREEN_TEXT}) to 'network-b' (Project ID: ${WHITE_TEXT}${PROJECT_ID_2}${GREEN_TEXT})...${RESET_FORMAT}"
gcloud compute networks peerings create peer-ab \
  --network=network-a \
  --peer-project=$PROJECT_ID_2 \
  --peer-network=network-b 

echo "${MAGENTA_TEXT}${BOLD_TEXT}⚙️ Switching gcloud configuration to Project ID 2: ${WHITE_TEXT}${PROJECT_ID_2}${RESET_FORMAT}"
gcloud config set project $PROJECT_ID_2

echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Creating network peering 'peer-ba' from 'network-b' (Project ID: ${WHITE_TEXT}${PROJECT_ID_2}${GREEN_TEXT}) to 'network-a' (Project ID: ${WHITE_TEXT}${PROJECT_ID}${GREEN_TEXT})...${RESET_FORMAT}"
gcloud compute networks peerings create peer-ba \
  --network=network-b \
  --peer-project=$PROJECT_ID \
  --peer-network=network-a


echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

