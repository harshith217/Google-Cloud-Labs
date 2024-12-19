#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo ""

read -p "${YELLOW_COLOR}${BOLD_TEXT}Enter region: ${RESET_FORMAT}" REGION
export REGION=$REGION


gcloud auth list
# export PROJECT_ID=$(gcloud config get-value project)

git clone --depth 1 https://github.com/GoogleCloudPlatform/training-data-analyst.git
cd ~/training-data-analyst/courses/design-process/deploying-apps-to-gcp

sudo pip install -r requirements.txt
echo "runtime: python39" > app.yaml

gcloud app create --region=$REGION
gcloud app deploy --version=one --quiet

echo '{
  "type": "pubsub",
  "displayName": "arcadecrew",
  "labels": {
    "topic": "projects/'"$DEVSHELL_PROJECT_ID"'/topics/notificationTopic"
  }
}' > pubsub-channel.json

gcloud beta monitoring channels create --channel-content-from-file="pubsub-channel.json"

channel_info=$(gcloud beta monitoring channels list --format=json)
channel_id=$(echo "$channel_info" | jq -r '.[0].name' | sed 's/.*/\0\/notificationChannels\/\0/')

echo '{
  "displayName": "Hello too slow",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Response latency [MEAN] for 99th% over 8s",
      "conditionThreshold": {
        "filter": "resource.type = \"gae_app\" AND metric.type = \"appengine.googleapis.com/http/server/response_latencies\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_NONE",
            "perSeriesAligner": "ALIGN_PERCENTILE_99"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 8000
      }
    }
  ],
  "alertStrategy": {
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    "'"$channel_id"'"
  ]
}' > app-engine-error-percent-policy.json

gcloud alpha monitoring policies create --policy-from-file="app-engine-error-percent-policy.json"

cat > main.py <<EOF
from flask import Flask, render_template, request
import time
import random
import json
app = Flask(__name__)

@app.route("/")
def main():
    model = {"title": "Hello GCP."}
    time.sleep(10)
    return render_template('index.html', model=model)
EOF

gcloud app deploy --version=two --quiet

while true; do curl -s https://$DEVSHELL_PROJECT_ID.appspot.com/ | grep -e "<title>" -e "error";sleep .$[( $RANDOM % 10 )]s;done



echo ""
# Completion message
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

