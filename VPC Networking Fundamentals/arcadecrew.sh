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

# Prompt user for Zone 2
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter ZONE_2:${RESET_FORMAT}"
read -r ZONE_2

export ZONE_2
export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

#Instruction before create network
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a new VPC network named 'mynetwork'...${RESET_FORMAT}"
gcloud compute networks create mynetwork \
  --project=$DEVSHELL_PROJECT_ID \
  --subnet-mode=auto \
  --mtu=1460 \
  --bgp-routing-mode=regional
echo "${GREEN_TEXT}${BOLD_TEXT}Successfully created mynetwork!${RESET_FORMAT}"

#Instruction before first vm create
echo "${BLUE_TEXT}${BOLD_TEXT}Creating the first VM instance 'mynet-us-vm' in zone: ${ZONE_1}...${RESET_FORMAT}"
gcloud compute instances create mynet-us-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE_1 \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=mynet-us-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_1/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any
echo "${GREEN_TEXT}${BOLD_TEXT}Successfully created mynet-us-vm!${RESET_FORMAT}"

#Instruction before second vm create
echo "${BLUE_TEXT}${BOLD_TEXT}Creating the second VM instance 'mynet-second-vm' in zone: ${ZONE_2}...${RESET_FORMAT}"
gcloud compute instances create mynet-second-vm \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE_2 \
  --machine-type=e2-micro \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork \
  --metadata=enable-oslogin=true \
  --maintenance-policy=MIGRATE \
  --provisioning-model=STANDARD \
  --create-disk=auto-delete=yes,boot=yes,device-name=mynet-eu-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE_2/diskTypes/pd-balanced \
  --no-shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --labels=goog-ec-src=vm_add-gcloud \
  --reservation-affinity=any
echo "${GREEN_TEXT}${BOLD_TEXT}Successfully created mynet-second-vm!${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
