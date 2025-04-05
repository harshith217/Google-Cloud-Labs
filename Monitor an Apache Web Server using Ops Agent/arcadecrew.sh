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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for entering the zone
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the Zone:${RESET_FORMAT}"
read ZONE

# Informing about VM creation
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a VM instance named 'quickstart-vm' in the specified zone...${RESET_FORMAT}"
gcloud compute instances create quickstart-vm --zone=$ZONE --machine-type=e2-small --tags=http-server,https-server --create-disk=auto-delete=yes,boot=yes,device-name=quickstart-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20241009,mode=rw,size=10,type=pd-balanced

# Informing about firewall rules
echo "${CYAN_TEXT}${BOLD_TEXT}Setting up firewall rules to allow HTTP and HTTPS traffic...${RESET_FORMAT}"
gcloud compute firewall-rules create allow-http-from-internet --target-tags=http-server --allow tcp:80 --source-ranges 0.0.0.0/0 --description="Allow HTTP from the internet"

gcloud compute firewall-rules create allow-https-from-internet --target-tags=https-server --allow tcp:443 --source-ranges 0.0.0.0/0 --description="Allow HTTPS from the internet"

# Informing about script preparation
echo "${GREEN_TEXT}${BOLD_TEXT}Preparing the disk setup script for Apache and Ops Agent installation...${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'

sudo apt-get update && sudo apt-get install apache2 php7.0 -y

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Configures Ops Agent to collect telemetry from the app and restart Ops Agent.

set -e

# Create a back up of the existing file so existing configurations are not lost.
sudo cp /etc/google-cloud-ops-agent/config.yaml /etc/google-cloud-ops-agent/config.yaml.bak

# Configure the Ops Agent.
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOF
metrics:
  receivers:
    apache:
      type: apache
  service:
    pipelines:
      apache:
        receivers:
          - apache
logging:
  receivers:
    apache_access:
      type: apache_access
    apache_error:
      type: apache_error
  service:
    pipelines:
      apache:
        receivers:
          - apache_access
          - apache_error
EOF

sudo service google-cloud-ops-agent restart
sleep 60

EOF_END

# Informing about file transfer
echo "${CYAN_TEXT}${BOLD_TEXT}Transferring the setup script to the VM instance...${RESET_FORMAT}"
gcloud compute scp prepare_disk.sh quickstart-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# Informing about script execution
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing the setup script on the VM instance...${RESET_FORMAT}"
gcloud compute ssh quickstart-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

# Informing about email channel creation
echo "${CYAN_TEXT}${BOLD_TEXT}Creating an email notification channel...${RESET_FORMAT}"
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "ArcadeCrew",
  "description": "Subscribe",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"

# Get the channel ID
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Informing about alert policy creation
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating an alert policy for Apache traffic monitoring...${RESET_FORMAT}"
cat > vm-alert-policy.json <<EOF_END
{
  "displayName": "Apache traffic above threshold",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - workload/apache.traffic",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"workload.googleapis.com/apache.traffic\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 4000
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "1800s",
    "notificationPrompts": [
      "OPENED"
    ]
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$email_channel_id"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END

# Create the alert policy
gcloud alpha monitoring policies create --policy-from-file=vm-alert-policy.json

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
