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

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Attempting to retrieve the default ZONE from your GCP project metadata...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Default ZONE could not be determined automatically.${RESET_FORMAT}"
  echo "${BLUE_TEXT}${BOLD_TEXT}✍️ Please enter the ZONE: ${RESET_FORMAT}"
  read -r ZONE
  while [ -z "$ZONE" ]; do
    echo "${RED_TEXT}${BOLD_TEXT}🚫 ZONE cannot be empty. Please provide a valid ZONE: ${RESET_FORMAT}"
    read -r ZONE
  done
fi
export ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Using ZONE: ${ZONE}${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Attempting to retrieve the default REGION from your GCP project metadata...${RESET_FORMAT}"
REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️ Default REGION could not be determined from metadata.${RESET_FORMAT}"
  if [ -n "$ZONE" ]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}⚙️ Trying to derive REGION from the provided ZONE ('${ZONE}')...${RESET_FORMAT}"
    DERIVED_REGION=$(echo "${ZONE::-2}")
    if [ -n "$DERIVED_REGION" ]; then
      REGION=$DERIVED_REGION
      echo "${GREEN_TEXT}${BOLD_TEXT}👍 Successfully derived REGION: ${REGION}${RESET_FORMAT}"
    else
      echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to derive REGION from ZONE '${ZONE}'. The ZONE might be too short or malformed.${RESET_FORMAT}"
    fi
  else
    echo "${RED_TEXT}${BOLD_TEXT}❗ ZONE is not set, so REGION cannot be derived.${RESET_FORMAT}"
  fi
fi

if [ -z "$REGION" ]; then
  echo "${BLUE_TEXT}${BOLD_TEXT}✍️ Please enter the REGION: ${RESET_FORMAT}"
  read -r REGION
  while [ -z "$REGION" ]; do
    echo "${RED_TEXT}${BOLD_TEXT}🚫 REGION cannot be empty. Please provide a valid REGION: ${RESET_FORMAT}"
    read -r REGION
  done
fi
export REGION
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Using REGION: ${REGION}${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🛠️  Creating a custom VPC network named 'ca-lab-vpc'...${RESET_FORMAT}"
gcloud compute networks create ca-lab-vpc --subnet-mode custom

echo "${CYAN_TEXT}${BOLD_TEXT}🛠️  Creating a subnet 'ca-lab-subnet' within 'ca-lab-vpc' in region ${REGION}...${RESET_FORMAT}"
gcloud compute networks subnets create ca-lab-subnet \
        --network ca-lab-vpc --range 10.0.0.0/24 --region $REGION

echo "${CYAN_TEXT}${BOLD_TEXT}🔥 Creating a firewall rule 'allow-js-site' to allow TCP traffic on port 3000...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-js-site --allow tcp:3000 --network ca-lab-vpc

echo "${CYAN_TEXT}${BOLD_TEXT}🔥 Creating a firewall rule 'allow-health-check' for GCP health checkers...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-health-check \
    --network=ca-lab-vpc \
    --action=allow \
    --direction=ingress \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-healthcheck \
    --rules=tcp

echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Deploying a containerized OWASP Juice Shop instance 'owasp-juice-shop-app' in zone ${ZONE}...${RESET_FORMAT}"
gcloud compute instances create-with-container owasp-juice-shop-app --container-image bkimminich/juice-shop \
     --network ca-lab-vpc \
     --subnet ca-lab-subnet \
     --private-network-ip=10.0.0.3 \
     --machine-type n1-standard-2 \
     --zone $ZONE \
     --tags allow-healthcheck

echo "${CYAN_TEXT}${BOLD_TEXT}➕ Creating an unmanaged instance group 'juice-shop-group' in zone ${ZONE}...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged create juice-shop-group \
    --zone=$ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Adding 'owasp-juice-shop-app' instance to 'juice-shop-group'...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged add-instances juice-shop-group \
    --zone=$ZONE \
    --instances=owasp-juice-shop-app

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️  Setting named port 'http:3000' for 'juice-shop-group'...${RESET_FORMAT}"
gcloud compute instance-groups unmanaged set-named-ports \
juice-shop-group \
   --named-ports=http:3000 \
   --zone=$ZONE

echo "${CYAN_TEXT}${BOLD_TEXT}🩺 Creating a TCP health check 'tcp-port-3000' for port 3000...${RESET_FORMAT}"
gcloud compute health-checks create tcp tcp-port-3000 \
        --port 3000

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️  Creating a global backend service 'juice-shop-backend'...${RESET_FORMAT}"
gcloud compute backend-services create juice-shop-backend \
        --protocol HTTP \
        --port-name http \
        --health-checks tcp-port-3000 \
        --enable-logging \
        --global

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Adding 'juice-shop-group' as a backend to 'juice-shop-backend'...${RESET_FORMAT}"
gcloud compute backend-services add-backend juice-shop-backend \
        --instance-group=juice-shop-group \
        --instance-group-zone=$ZONE \
        --global

echo "${CYAN_TEXT}${BOLD_TEXT}🗺️  Creating a URL map 'juice-shop-loadbalancer' for the backend service...${RESET_FORMAT}"
gcloud compute url-maps create juice-shop-loadbalancer \
        --default-service juice-shop-backend

echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Creating an HTTP proxy 'juice-shop-proxy' using the URL map...${RESET_FORMAT}"
gcloud compute target-http-proxies create juice-shop-proxy \
        --url-map juice-shop-loadbalancer

echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Creating a global forwarding rule 'juice-shop-rule' to route traffic to the proxy on port 80...${RESET_FORMAT}"
gcloud compute forwarding-rules create juice-shop-rule \
        --global \
        --target-http-proxy=juice-shop-proxy \
        --ports=80

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Fetching the public IP address of the forwarding rule...${RESET_FORMAT}"
PUBLIC_SVC_IP="$(gcloud compute forwarding-rules describe juice-shop-rule  --global --format="value(IPAddress)")"
echo "${GREEN_TEXT}${BOLD_TEXT}🌍 Public Service IP: ${PUBLIC_SVC_IP}${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}🔁 Checking if the server at ${PUBLIC_SVC_IP} is responding (this may take a moment)...${RESET_FORMAT}"
while true; do
    cloud=$(curl -Ii http://$PUBLIC_SVC_IP 2>/dev/null) # Added 2>/dev/null to suppress curl progress
    if [[ "$cloud" == *"HTTP/1.1 200 OK"* ]]; then
        echo "${GREEN_TEXT}${BOLD_TEXT}✅ Server is up and serving requests!${RESET_FORMAT}"
        break
    else
      echo "${YELLOW_TEXT}${BOLD_TEXT}⏳ Waiting for the server to become available... ${RESET_FORMAT}"
      echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW (https://www.youtube.com/@Arcade61432)${RESET_FORMAT}"
      for i in {7..1}; do
        echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r${i} seconds remaining... ${RESET_FORMAT}"
        sleep 1
      done
      echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}Checking again...        ${RESET_FORMAT}\n" # Clear the line and add a newline
    fi
done

echo "${CYAN_TEXT}${BOLD_TEXT}📜 Listing preconfigured WAF expression sets from Cloud Armor...${RESET_FORMAT}"
gcloud compute security-policies list-preconfigured-expression-sets

echo "${CYAN_TEXT}${BOLD_TEXT}🛡️  Creating a new security policy 'block-with-modsec-crs'...${RESET_FORMAT}"
gcloud compute security-policies create block-with-modsec-crs \
    --description "Block with OWASP ModSecurity CRS"

echo "${CYAN_TEXT}${BOLD_TEXT}룰 Updating the default rule (priority 2147483647) in 'block-with-modsec-crs' to 'deny-403'...${RESET_FORMAT}"
gcloud compute security-policies rules update 2147483647 \
    --security-policy block-with-modsec-crs \
    --action "deny-403"

echo "${CYAN_TEXT}${BOLD_TEXT}🔍 Fetching your current public IP address...${RESET_FORMAT}"
MY_IP=$(curl -s ifconfig.me) # Added -s for silent curl
echo "${GREEN_TEXT}${BOLD_TEXT}🏠 Your IP: ${MY_IP}${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}➕ Adding a rule (priority 10000) to 'block-with-modsec-crs' to allow traffic from your IP (${MY_IP})...${RESET_FORMAT}"
gcloud compute security-policies rules create 10000 \
    --security-policy block-with-modsec-crs  \
    --description "allow traffic from my IP" \
    --src-ip-ranges "$MY_IP/32" \
    --action "allow"

echo "${CYAN_TEXT}${BOLD_TEXT}🧱 Adding a rule (priority 9000) to block Local File Inclusion (LFI) attacks...${RESET_FORMAT}"
gcloud compute security-policies rules create 9000 \
    --security-policy block-with-modsec-crs  \
    --description "block local file inclusion" \
     --expression "evaluatePreconfiguredExpr('lfi-stable')" \
    --action deny-403

echo "${CYAN_TEXT}${BOLD_TEXT}🧱 Adding a rule (priority 9001) to block Remote Code Execution (RCE) attacks...${RESET_FORMAT}"
gcloud compute security-policies rules create 9001 \
    --security-policy block-with-modsec-crs  \
    --description "block rce attacks" \
     --expression "evaluatePreconfiguredExpr('rce-stable')" \
    --action deny-403

echo "${CYAN_TEXT}${BOLD_TEXT}🧱 Adding a rule (priority 9002) to block common scanners...${RESET_FORMAT}"
gcloud compute security-policies rules create 9002 \
    --security-policy block-with-modsec-crs  \
    --description "block scanners" \
     --expression "evaluatePreconfiguredExpr('scannerdetection-stable')" \
    --action deny-403

echo "${CYAN_TEXT}${BOLD_TEXT}🧱 Adding a rule (priority 9003) to block protocol attacks...${RESET_FORMAT}"
gcloud compute security-policies rules create 9003 \
    --security-policy block-with-modsec-crs  \
    --description "block protocol attacks" \
     --expression "evaluatePreconfiguredExpr('protocolattack-stable')" \
    --action deny-403

echo "${CYAN_TEXT}${BOLD_TEXT}🧱 Adding a rule (priority 9004) to block session fixation attacks...${RESET_FORMAT}"
gcloud compute security-policies rules create 9004 \
    --security-policy block-with-modsec-crs \
    --description "block session fixation attacks" \
     --expression "evaluatePreconfiguredExpr('sessionfixation-stable')" \
    --action deny-403

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Attaching the security policy 'block-with-modsec-crs' to the 'juice-shop-backend' service...${RESET_FORMAT}"
gcloud compute backend-services update juice-shop-backend \
    --security-policy block-with-modsec-crs \
    --global


echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
