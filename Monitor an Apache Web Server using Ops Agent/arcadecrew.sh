# Define color codes for output formatting
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`

BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`

echo "${BACKGROUND_RED}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

# List all authenticated accounts
gcloud auth list

# Set and capture the active project ID
export ACTIVE_PROJECT=$(gcloud config get-value project)

# Assign project ID from the environment variable if available
export ACTIVE_PROJECT=$DEVSHELL_PROJECT_ID

# Prompt user to enter the desired compute zone
read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter ZONE:${RESET_FORMAT} " ZONE

# Apply the zone setting for compute operations
gcloud config set compute/zone $ZONE

# Launch a VM with specified parameters and set up firewall rules for HTTP/HTTPS
gcloud compute instances create demo-vm \
    --project=$DEVSHELL_PROJECT_ID \
    --zone=$ZONE \
    --machine-type=e2-small \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --tags=http-server,https-server && \
gcloud compute firewall-rules create allow-http \
    --target-tags=http-server \
    --allow tcp:80 \
    --description="Enable HTTP access" && \
gcloud compute firewall-rules create allow-https \
    --target-tags=https-server \
    --allow tcp:443 \
    --description="Enable HTTPS access"

# Write a script to install Apache and Google Ops Agent on the VM
cat > setup_apache_agent.sh <<'SCRIPT_END'

# Update package lists and install Apache, PHP
sudo apt-get update && sudo apt-get install apache2 php7.0 -y

# Download and execute Ops Agent installation script
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Backup existing Ops Agent config and apply new telemetry settings
set -e
sudo cp /etc/google-cloud-ops-agent/config.yaml /etc/google-cloud-ops-agent/config.yaml.bak
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << AGENT_CONFIG
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
AGENT_CONFIG

# Restart the Ops Agent service and allow time for the update
sudo service google-cloud-ops-agent restart
sleep 60

SCRIPT_END

# Transfer the script to the instance and run it
gcloud compute scp setup_apache_agent.sh demo-vm:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
gcloud compute ssh demo-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/setup_apache_agent.sh"

# Create a JSON file to define a Pub/Sub notification channel
cat > pubsub_channel_config.json <<'CHANNEL_JSON'
{
  "type": "pubsub",
  "displayName": "MyNotificationChannel",
  "description": "Subscription channel for notifications",
  "labels": {
    "topic": "projects/$DEVSHELL_PROJECT_ID/topics/alertTopic"
  }
}
CHANNEL_JSON

# Set up a new monitoring notification channel using the config file
gcloud beta monitoring channels create --channel-content-from-file=pubsub_channel_config.json

# Retrieve the notification channel ID for alerting
channel_info=$(gcloud beta monitoring channels list)
channel_ref=$(echo "$channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Define an alert policy for Apache traffic and save it in a JSON file
cat > traffic_alert_policy.json <<ALERT_POLICY_JSON
{
  "displayName": "High Apache Traffic Alert",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "High Traffic on Apache",
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
    "autoClose": "1800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "$channel_ref"
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
ALERT_POLICY_JSON

# Apply the alert policy based on the JSON file
gcloud alpha monitoring policies create --policy-from-file=traffic_alert_policy.json


# Completion message
echo -e "${RED_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Check out our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET_FORMAT}"
