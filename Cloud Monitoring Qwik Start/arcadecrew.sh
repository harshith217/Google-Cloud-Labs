#!/bin/bash

# --- Color Variables ---
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
# --- End Color Variables ---

clear
# --- Welcome Message ---
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING LAB SETUP...     ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo
# --- End Welcome Message ---

# --- Step 1: Set Zone/Region ---
echo "${GREEN_TEXT}${BOLD_TEXT}Step 1: Setting up Zone and Region...${RESET_FORMAT}"
# Use lab-specified values directly
export ZONE="us-central1-c"
export REGION="us-central1"

# Optional: Set gcloud config defaults
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION

echo "${CYAN_TEXT}Using Zone:   $ZONE${RESET_FORMAT}"
echo "${CYAN_TEXT}Using Region: $REGION${RESET_FORMAT}"
echo "${CYAN_TEXT}Project ID:   $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
# --- End Step 1 ---

# --- Step 2: Create VM Instance (Aligned with Lab Task 1) ---
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Creating the VM instance (lamp-1-vm)...${RESET_FORMAT}"

# Find the latest Debian 12 image
LATEST_DEBIAN_12_IMAGE=$(gcloud compute images list --project=debian-cloud --filter="family=debian-12" --sort-by=~creationTimestamp --limit=1 --format="value(selfLink)")

if [ -z "$LATEST_DEBIAN_12_IMAGE" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not find latest Debian 12 image. Exiting.${RESET_FORMAT}"
fi
echo "${CYAN_TEXT}Using Image: $LATEST_DEBIAN_12_IMAGE${RESET_FORMAT}"

gcloud compute instances create lamp-1-vm \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    # --metadata=enable-oslogin=true \ # REMOVED THIS LINE - Crucial Fix for SSH
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --tags=http-server \ # Keep tag for firewall rule
    --create-disk=auto-delete=yes,boot=yes,device-name=lamp-1-vm,image=$LATEST_DEBIAN_12_IMAGE,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \ # Use pd-standard as likely default
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=goog-ec-src=vm_add-gcloud \
    --reservation-affinity=any

# Check if VM creation was successful
if [ $? -ne 0 ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Failed to create VM instance. Exiting.${RESET_FORMAT}"
fi
# --- End Step 2 ---

# --- Step 3: Create Firewall Rule (Equivalent to Lab Checkbox) ---
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 3: Creating firewall rule for HTTP traffic...${RESET_FORMAT}"

# Check if rule already exists (idempotency)
if ! gcloud compute firewall-rules describe allow-http --project=$DEVSHELL_PROJECT_ID > /dev/null 2>&1; then
    gcloud compute firewall-rules create allow-http \
        --project=$DEVSHELL_PROJECT_ID \
        --direction=INGRESS \
        --priority=1000 \
        --network=default \
        --action=ALLOW \
        --rules=tcp:80 \
        --source-ranges=0.0.0.0/0 \
        --target-tags=http-server
else
    echo "${CYAN_TEXT}Firewall rule 'allow-http' already exists.${RESET_FORMAT}"
fi
# --- End Step 3 ---

# --- Step 4: Install Software & Ops Agent (Aligned with Lab Task 2) ---
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 4: Installing Apache, PHP, and Ops Agent on VM...${RESET_FORMAT}"

# Prepare the combined installation script
cat > install_lamp_agent.sh <<'EOF_END'
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive # Prevent prompts

echo ">>> Updating package list..."
sudo apt-get update -y

echo ">>> Installing Apache and PHP..."
# Install default PHP version for Debian 12 and the Apache module
sudo apt-get install -y apache2 php libapache2-mod-php

echo ">>> Restarting Apache..."
sudo systemctl restart apache2

echo ">>> Installing Google Cloud Ops Agent..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install --remove-repo

echo ">>> Checking Ops Agent status..."
sudo systemctl status google-cloud-ops-agent"*" || echo "Ops Agent status check command failed, but installation might still be okay."

echo ">>> Cleaning up script..."
rm -f /tmp/install_lamp_agent.sh

echo ">>> Installation script finished."
EOF_END

# Give script execute permissions
chmod +x install_lamp_agent.sh

# Wait a bit for SSH to become ready after VM creation
echo "${CYAN_TEXT}Waiting 30 seconds for SSH service to initialize on the VM...${RESET_FORMAT}"
sleep 30

# Copy the script to the VM
echo "${CYAN_TEXT}Copying installation script to VM...${RESET_FORMAT}"
gcloud compute scp ./install_lamp_agent.sh lamp-1-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

if [ $? -ne 0 ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Failed to copy script via SCP. Check SSH connectivity manually.${RESET_FORMAT}"
    echo "${RED_TEXT}Try: gcloud compute ssh lamp-1-vm --zone $ZONE --project $DEVSHELL_PROJECT_ID${RESET_FORMAT}"
fi

# Execute the script on the VM
echo "${CYAN_TEXT}Executing installation script on VM via SSH...${RESET_FORMAT}"
gcloud compute ssh lamp-1-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="sudo bash /tmp/install_lamp_agent.sh"

if [ $? -ne 0 ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Failed to execute script via SSH.${RESET_FORMAT}"
fi

# Clean up local script file
rm ./install_lamp_agent.sh
# --- End Step 4 ---


# --- Prompt for User Email ---
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 5.5: Configure Notification Email...${RESET_FORMAT}" # Added as an intermediate step

# Initialize USER_EMAIL as empty
USER_EMAIL=""

# Loop until a non-empty email is provided
while [ -z "$USER_EMAIL" ]; do
  # Prompt the user for their email address
  read -p "${CYAN_TEXT}Enter the email address for Monitoring notifications: ${RESET_FORMAT}" USER_EMAIL

  # Check if the input is empty and prompt again if it is
  if [ -z "$USER_EMAIL" ]; then
    echo "${RED_TEXT}Email address cannot be empty. Please try again.${RESET_FORMAT}"
  fi
done

echo "${GREEN_TEXT}Using email address: ${USER_EMAIL} for notifications.${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 5: Creating Uptime Check (Automated)...${RESET_FORMAT}"
# Wait for instance to be fully running and network reachable
echo "${CYAN_TEXT}Waiting 60 seconds for instance networking to stabilize...${RESET_FORMAT}"
sleep 60

# Use Instance Name directly for monitored resource if possible, otherwise get ID
# Note: API might prefer ID, but let's try name first for simplicity matching UI concept
export INSTANCE_NAME="lamp-1-vm" # Use name as it's simpler if API allows

# Check if Uptime Check already exists
UPTIME_CHECK_EXISTS=$(curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://monitoring.googleapis.com/v3/projects/$DEVSHELL_PROJECT_ID/uptimeCheckConfigs" | grep '"displayName": "Lamp Uptime Check"')

if [ -z "$UPTIME_CHECK_EXISTS" ]; then
  curl -s -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    "https://monitoring.googleapis.com/v3/projects/$DEVSHELL_PROJECT_ID/uptimeCheckConfigs" \
    -d "$(cat <<EOF
{
  "displayName": "Lamp Uptime Check",
  "monitoredResource": {
    "type": "gce_instance",
    "labels": {
      "project_id": "$DEVSHELL_PROJECT_ID",
      "instance_id": "$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --project=$DEVSHELL_PROJECT_ID --format='value(id)')",
      "zone": "$ZONE"
     }
  },
  "httpCheck": {
    "path": "/",
    "port": 80,
    "requestMethod": "GET",
    "useSsl": false
  },
  "period": "60s", # 1 minute check frequency
  "timeout": "10s"
}
EOF
)"
  echo "${CYAN_TEXT}Uptime Check created.${RESET_FORMAT}"
else
  echo "${CYAN_TEXT}Uptime Check 'Lamp Uptime Check' already exists.${RESET_FORMAT}"
fi

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Setting up email notification channel (Automated)...${RESET_FORMAT}"

# Create JSON for channel
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "Email-User-${USER_EMAIL}", # Make display name unique
  "description": "Notification channel for $USER_EMAIL",
  "labels": {
    "email_address": "$USER_EMAIL"
  },
  "enabled": true
}
EOF_END

# Check if channel exists by display name (less reliable than ID but easier here)
EXISTING_CHANNEL=$(gcloud beta monitoring channels list --project=$DEVSHELL_PROJECT_ID --filter="displayName=Email-User-${USER_EMAIL}" --format="value(name)")

if [ -z "$EXISTING_CHANNEL" ]; then
  gcloud beta monitoring channels create --channel-content-from-file="email-channel.json" --project=$DEVSHELL_PROJECT_ID
  # Get the channel ID more reliably after creation
  email_channel_id=$(gcloud beta monitoring channels list --project=$DEVSHELL_PROJECT_ID --filter="displayName=Email-User-${USER_EMAIL}" --format="value(name)")
  echo "${CYAN_TEXT}Email channel created with ID: $email_channel_id${RESET_FORMAT}"
else
  email_channel_id=$EXISTING_CHANNEL
  echo "${CYAN_TEXT}Email channel 'Email-User-${USER_EMAIL}' already exists with ID: $email_channel_id${RESET_FORMAT}"
fi
rm email-channel.json # Clean up

if [ -z "$email_channel_id" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Could not create or find email notification channel. Exiting.${RESET_FORMAT}"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 7: Creating Monitoring Policy for Inbound Traffic (Automated)...${RESET_FORMAT}"

# Create Policy JSON
cat > inbound-traffic-policy.json <<EOF_END
{
  "displayName": "Inbound Traffic Alert",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "VM Instance - Network traffic - Inbound > 500 B/s",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"agent.googleapis.com/interface/traffic\" AND metric.label.state = \"RX\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "60s", # 1 minute retest window
        "trigger": {
          "count": 1
        },
        "thresholdValue": 500
      }
    }
  ],
  "alertStrategy": {
     "autoClose": "604800s" # Auto-close after 7 days
  },
  "notificationChannels": [
    "$email_channel_id"
  ],
  "documentation": {
      "content": "Alert triggered when inbound network traffic on lamp-1-vm exceeds 500 Bytes/sec for 1 minute. Check instance activity.",
      "mimeType": "text/markdown"
   },
  "enabled": true
}
EOF_END

# Check if policy exists by display name
EXISTING_POLICY=$(gcloud alpha monitoring policies list --project=$DEVSHELL_PROJECT_ID --filter='displayName="Inbound Traffic Alert"' --format='value(name)')

if [ -z "$EXISTING_POLICY" ]; then
  gcloud alpha monitoring policies create --policy-from-file="inbound-traffic-policy.json" --project=$DEVSHELL_PROJECT_ID
  echo "${CYAN_TEXT}Alerting policy created.${RESET_FORMAT}"
else
   echo "${CYAN_TEXT}Alerting policy 'Inbound Traffic Alert' already exists.${RESET_FORMAT}"
fi
rm inbound-traffic-policy.json # Clean up

# --- End Steps 5, 6, 7 ---


# --- Final Message ---
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}          SCRIPT EXECUTION COMPLETED                 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}NOTE: Monitoring/Alerting steps were automated.${RESET_FORMAT}"
echo "${YELLOW_TEXT}The lab expects you to perform Tasks 3 and 4 manually via the Cloud Console UI.${RESET_FORMAT}"
echo "${YELLOW_TEXT}You should still explore the Monitoring section in the Console to see the created resources.${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
# --- End Final Message ---
