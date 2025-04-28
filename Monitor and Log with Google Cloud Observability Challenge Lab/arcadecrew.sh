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
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter the desired metric name:${RESET_FORMAT}"
read METRIC
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Please enter the threshold value for the alert:${RESET_FORMAT}"
read VALUE

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Enabling the Cloud Monitoring API...${RESET_FORMAT}"
gcloud services enable monitoring.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Monitoring API enabled successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔍 Retrieving the zone for the 'video-queue-monitor' instance...${RESET_FORMAT}"
export ZONE=$(gcloud compute instances list video-queue-monitor --format 'csv[no-heading](zone)')
echo "${GREEN_TEXT}${BOLD_TEXT}Zone retrieved: ${ZONE}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🌍 Determining the region based on the zone...${RESET_FORMAT}"
export REGION="${ZONE%-*}"
echo "${GREEN_TEXT}${BOLD_TEXT}Region determined: ${REGION}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Fetching the instance ID for 'video-queue-monitor'...${RESET_FORMAT}"
export INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor --project="$DEVSHELL_PROJECT_ID" --zone="$ZONE" --format="get(id)")
echo "${GREEN_TEXT}${BOLD_TEXT}Instance ID fetched: ${INSTANCE_ID}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛑 Stopping the 'video-queue-monitor' instance temporarily...${RESET_FORMAT}"
gcloud compute instances stop video-queue-monitor --zone $ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Instance 'video-queue-monitor' stopped.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Creating the startup script (startup-script.sh)...${RESET_FORMAT}"
cat > startup-script.sh <<EOF_START
#!/bin/bash

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.22.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.8.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

mkdir /work
mkdir /work/go
mkdir /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

cd /work/go
mkdir video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

export MY_PROJECT_ID=$DEVSHELL_PROJECT_ID
export MY_GCE_INSTANCE_ID=$INSTANCE_ID
export MY_GCE_INSTANCE_ZONE=$ZONE

cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF_START
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Startup script created successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Adding the startup script metadata to 'video-queue-monitor'...${RESET_FORMAT}"
gcloud compute instances add-metadata video-queue-monitor \
  --zone $ZONE \
  --metadata-from-file startup-script=startup-script.sh
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Metadata added successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}▶️ Starting the 'video-queue-monitor' instance...${RESET_FORMAT}"
gcloud compute instances start video-queue-monitor --zone $ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Instance 'video-queue-monitor' started. The startup script will now execute.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📊 Creating a logs-based metric named '${METRIC}'...${RESET_FORMAT}"
gcloud logging metrics create $METRIC \
    --description="Metric for high resolution video uploads" \
    --log-filter='textPayload=("file_format=4K" OR "file_format=8K")'
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Logs-based metric '${METRIC}' created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📧 Creating the email notification channel configuration file (email-channel.json)...${RESET_FORMAT}"
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "arcadecrew",
  "description": "subscribe",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Email channel configuration file created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📡 Creating the email notification channel in Cloud Monitoring...${RESET_FORMAT}"
gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Email notification channel created. ${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Retrieving the ID of the newly created email notification channel...${RESET_FORMAT}"
email_channel_info=$(gcloud beta monitoring channels list)
email_channel_id=$(echo "$email_channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)
echo "${GREEN_TEXT}${BOLD_TEXT}Email channel ID retrieved: ${email_channel_id}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📜 Creating the alert policy configuration file (arcadecrew.json)...${RESET_FORMAT}"
cat > arcadecrew.json <<EOF_END
{
  "displayName": "arcadecrew",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "VM Instance - logging/user/large_video_upload_rate",
      "conditionThreshold": {
        "filter": "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/$METRIC\"",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_RATE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": $VALUE
      }
    }
  ],
  "alertStrategy": {
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
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Alert policy configuration file created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚨 Creating the alert policy in Cloud Monitoring...${RESET_FORMAT}"
gcloud alpha monitoring policies create --policy-from-file=arcadecrew.json
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Alert policy created successfully.${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 Monitoring Dashboard Link:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}""https://console.cloud.google.com/monitoring/dashboards?project=$DEVSHELL_PROJECT_ID"""${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}📈 Expected Metrics: input_queue_size, ${METRIC}${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
