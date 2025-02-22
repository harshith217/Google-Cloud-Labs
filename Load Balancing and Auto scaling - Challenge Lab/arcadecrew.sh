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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Prompt user input with clear instructions
echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter the required values:${RESET_FORMAT}"
echo "${MAGENTA_TEXT}Enter REGION_2 (e.g., us-west1):${RESET_FORMAT}"
read -p "REGION_2: " REGION_2
echo "${MAGENTA_TEXT}Enter ZONE_3:${RESET_FORMAT}"
read -p "ZONE_3: " ZONE_3

# Fetch project details
echo "${GREEN_TEXT}${BOLD_TEXT}Fetching default region and zone...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

PROJECT_ID=`gcloud config get-value project`

echo "${GREEN_TEXT}Default REGION: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}Default ZONE: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}Project ID: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

# Create startup script
echo "${CYAN_TEXT}${BOLD_TEXT}Creating startup script...${RESET_FORMAT}"
cat > startup-script.sh <<EOF_END
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apache2
EOF_END

echo "${GREEN_TEXT}Startup script created successfully.${RESET_FORMAT}"

# Create instance template
echo "${CYAN_TEXT}${BOLD_TEXT}Creating Compute Engine instance template...${RESET_FORMAT}"
gcloud compute instance-templates create primecalc \
--metadata-from-file startup-script=startup-script.sh \
--no-address --tags http-health-check --machine-type=e2-medium

echo "${GREEN_TEXT}Instance template 'primecalc' created.${RESET_FORMAT}"

# Create health check
echo "${CYAN_TEXT}${BOLD_TEXT}Creating health check for instance groups...${RESET_FORMAT}"
gcloud compute health-checks create tcp http-health-check \
  --port=80 \
  --check-interval=5s \
  --timeout=5s \
  --unhealthy-threshold=3 \
  --healthy-threshold=2

echo "${GREEN_TEXT}Health check created successfully.${RESET_FORMAT}"

# Fetch available zones
echo "${CYAN_TEXT}${BOLD_TEXT}Fetching available zones in region $REGION...${RESET_FORMAT}"
AVAILABLE_ZONES=$(gcloud compute zones list --filter="region:($REGION)" --format="value(name)")
ZONE_LIST=$(echo $AVAILABLE_ZONES | tr '\n' ',' | sed 's/,$//')

echo "${GREEN_TEXT}Available zones for $REGION: ${BOLD_TEXT}$ZONE_LIST${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating managed instance group in $REGION...${RESET_FORMAT}"
gcloud beta compute instance-groups managed create $REGION-mig \
  --project=$PROJECT_ID \
  --base-instance-name=$REGION-mig \
  --template=projects/$PROJECT_ID/global/instanceTemplates/primecalc \
  --size=1 \
  --zones=$ZONE_LIST \
  --target-distribution-shape=EVEN \
  --instance-redistribution-type=proactive \
  --default-action-on-vm-failure=repair \
  --health-check=projects/$PROJECT_ID/global/healthChecks/http-health-check \
  --initial-delay=60 \
  --no-force-update-on-repair \
  --standby-policy-mode=manual \
  --list-managed-instances-results=pageless

echo "${GREEN_TEXT}Managed instance group created in $REGION.${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Setting up autoscaling...${RESET_FORMAT}"
gcloud beta compute instance-groups managed set-autoscaling $REGION-mig \
  --project=$PROJECT_ID \
  --region=$REGION \
  --mode=on \
  --min-num-replicas=1 \
  --max-num-replicas=2 \
  --target-cpu-utilization=0.8 \
  --cpu-utilization-predictive-method=none \
  --cool-down-period=60

echo "${GREEN_TEXT}Autoscaling configured successfully.${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating firewall rule for load balancer...${RESET_FORMAT}"
gcloud compute firewall-rules create lb-firewall-rule --network default --allow=tcp:80 \
--source-ranges 35.191.0.0/16 --target-tags http-health-check

echo "${GREEN_TEXT}Firewall rule 'lb-firewall-rule' created.${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating stress test VM in zone $ZONE_3...${RESET_FORMAT}"
gcloud compute instances create stress-test-vm \
--machine-type=e2-standard-2 --zone $ZONE_3
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
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo