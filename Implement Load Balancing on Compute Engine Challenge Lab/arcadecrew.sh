#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Start of the script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter the following details:${RESET_FORMAT}"
read -p "${MAGENTA_TEXT}Enter INSTANCE_NAME: ${NO_COLOR}" INSTANCE_NAME
read -p "${MAGENTA_TEXT}Enter FIREWALL_NAME: ${NO_COLOR}" FIREWALL_NAME
read -p "${MAGENTA_TEXT}Enter ZONE: ${NO_COLOR}" ZONE

echo "${GREEN_TEXT}${BOLD_TEXT}You entered:${RESET_FORMAT}"
echo "${GREEN_TEXT}INSTANCE_NAME: ${BOLD_TEXT}$INSTANCE_NAME${RESET_FORMAT}"
echo "${GREEN_TEXT}FIREWALL_NAME: ${BOLD_TEXT}$FIREWALL_NAME${RESET_FORMAT}"
echo "${GREEN_TEXT}ZONE: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"

export PORT=8082
export REGION="${ZONE%-*}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating network...${RESET_FORMAT}"
gcloud compute networks create nucleus-vpc --subnet-mode=auto

echo "${CYAN_TEXT}${BOLD_TEXT}Creating instance...${RESET_FORMAT}"
gcloud compute instances create $INSTANCE_NAME \
          --network nucleus-vpc \
          --zone $ZONE  \
          --machine-type e2-micro  \
          --image-family debian-12  \
          --image-project debian-cloud 

cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}Creating instance template...${RESET_FORMAT}"
gcloud compute instance-templates create web-server-template \
--metadata-from-file startup-script=startup.sh \
--network nucleus-vpc \
--machine-type e2-medium \
--region $ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}Creating target pool...${RESET_FORMAT}"
gcloud compute target-pools create nginx-pool --region=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Creating managed instance group...${RESET_FORMAT}"
gcloud compute instance-groups managed create web-server-group \
--base-instance-name web-server \
-- $REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Creating firewall rule...${RESET_FORMAT}"
gcloud compute firewall-rules create $FIREWALL_NAME \
--allow tcp:80 \
--network nucleus-vpc

echo "${CYAN_TEXT}${BOLD_TEXT}Creating health check...${RESET_FORMAT}"
gcloud compute http-health-checks create http-basic-check

echo "${CYAN_TEXT}${BOLD_TEXT}Setting named ports...${RESET_FORMAT}"
gcloud compute instance-groups managed \
set-named-ports web-server-group \
--named-ports http:80 \
--region $REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Creating backend service...${RESET_FORMAT}"
gcloud compute backend-services create web-server-backend \
--protocol HTTP \
--http-health-checks http-basic-check \
--global

echo "${CYAN_TEXT}${BOLD_TEXT}Adding backend to service...${RESET_FORMAT}"
gcloud compute backend-services add-backend web-server-backend \
--instance-group web-server-group \
--instance-group-region $REGION \
--global

echo "${CYAN_TEXT}${BOLD_TEXT}Creating URL map...${RESET_FORMAT}"
gcloud compute url-maps create web-server-map \
--default-service web-server-backend

echo "${CYAN_TEXT}${BOLD_TEXT}Creating HTTP proxy...${RESET_FORMAT}"
gcloud compute target-http-proxies create http-lb-proxy \
--url-map web-server-map

echo "${CYAN_TEXT}${BOLD_TEXT}Creating forwarding rule...${RESET_FORMAT}"
gcloud compute forwarding-rules create http-content-rule \
--global \
--target-http-proxy http-lb-proxy \
--ports 80

echo "${CYAN_TEXT}${BOLD_TEXT}Creating forwarding rule for firewall...${RESET_FORMAT}"
gcloud compute forwarding-rules create $FIREWALL_NAME \
--global \
--target-http-proxy http-lb-proxy \
--ports 80

echo "${CYAN_TEXT}${BOLD_TEXT}Listing forwarding rules...${RESET_FORMAT}"
gcloud compute forwarding-rules list
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo