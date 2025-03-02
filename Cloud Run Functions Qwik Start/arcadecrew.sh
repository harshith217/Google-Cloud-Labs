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

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Setting up Zone and Region ========================== ${RESET_FORMAT}"
echo
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)
gcloud config set compute/region $REGION
export PROJECT_ID=$(gcloud config get-value project)

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Getting and setting IAM Policy ========================== ${RESET_FORMAT}"
echo
gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID > policy.yaml

cat <<EOF >> policy.yaml
auditConfigs:
- auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
  service: compute.googleapis.com
EOF

gcloud projects set-iam-policy $DEVSHELL_PROJECT_ID policy.yaml

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling Required Services ========================== ${RESET_FORMAT}"
echo
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating and setting up hello-http directory and files ========================== ${RESET_FORMAT}"
echo
mkdir ~/hello-http && cd $_
touch index.js && touch package.json

cat > index.js <<EOF_END
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js in GCF 2nd gen!');
});
EOF_END

cat > package.json <<EOF_END
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF_END

deploy_function() {
  gcloud functions deploy nodejs-http-function \
    --gen2 \
    --runtime nodejs18 \
    --entry-point helloWorld \
    --source . \
    --region $REGION \
    --trigger-http \
    --timeout 600s \
    --max-instances 1 \
    --quiet
}

SERVICE_NAME="nodejs-http-function"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying and checking the service (nodejs-http-function) ========================== ${RESET_FORMAT}"
echo
# Loop until the Cloud Run service is created
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Run service is created
  if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done

echo "Running the next code..."

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Getting Project Number and service account ========================== ${RESET_FORMAT}"
echo

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Adding IAM policy binding ========================== ${RESET_FORMAT}"
echo

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher
  
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating and setting up hello-storage directory and files ========================== ${RESET_FORMAT}"
echo
mkdir ~/hello-storage && cd $_
touch index.js && touch package.json

cat > index.js <<EOF_END
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js in GCF 2nd gen!');
  console.log(cloudevent);
});
EOF_END

cat > package.json <<EOF_END
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF_END

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating bucket ========================== ${RESET_FORMAT}"
echo
BUCKET="gs://gcf-gen2-storage-$PROJECT_ID"
gsutil mb -l $REGION $BUCKET

deploy_function () {
gcloud functions deploy nodejs-storage-function \
  --gen2 \
  --runtime nodejs18 \
  --entry-point helloStorage \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 1 \
  --quiet
}

# Variables
SERVICE_NAME="nodejs-storage-function"
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying and checking the service (nodejs-storage-function) ========================== ${RESET_FORMAT}"
echo

# Loop until the Cloud Run service is created
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Run service is created
  if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done

# Your next code to run after the Cloud Run service is created
echo "Running the next code..."
# Add your next code here

### ``` If you facing error re-run the above command again and again... 
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Uploading file to bucket and read logs ========================== ${RESET_FORMAT}"
echo
echo "Hello World" > random.txt
gsutil cp random.txt $BUCKET/random.txt

gcloud functions logs read nodejs-storage-function \
  --region $REGION --gen2 --limit=100 --format "value(log)"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Adding IAM policy binding for eventarc ========================== ${RESET_FORMAT}"
echo

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/eventarc.eventReceiver

cd ~
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Cloning eventarc-samples repo ========================== ${RESET_FORMAT}"
echo
git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git

cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying gce-vm-labeler function ========================== ${RESET_FORMAT}"
echo

gcloud functions deploy gce-vm-labeler \
  --gen2 \
  --runtime nodejs18 \
  --entry-point labelVmCreation \
  --source . \
  --region $REGION \
  --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
  --trigger-location $REGION \
  --max-instances 1

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating a GCE instance ========================== ${RESET_FORMAT}"
echo

gcloud compute instances create instance-1 --zone=$ZONE

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Setting up hello-world-colored directory and files ========================== ${RESET_FORMAT}"
echo

mkdir ~/hello-world-colored && cd $_
touch main.py

cat > main.py <<EOF_END
import os

color = os.environ.get('COLOR')

def hello_world(request):
    return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
EOF_END

echo > requirements.txt 

COLOR=yellow
echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying hello-world-colored function ========================== ${RESET_FORMAT}"
echo

gcloud functions deploy hello-world-colored \
  --gen2 \
  --runtime python39 \
  --entry-point hello_world \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars COLOR=$COLOR \
  --max-instances 1 \
  --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Setting up min-instances directory and files ========================== ${RESET_FORMAT}"
echo
mkdir ~/min-instances && cd $_
touch main.go

cat > main.go <<EOF_END
package p

import (
        "fmt"
        "net/http"
        "time"
)

func init() {
        time.Sleep(10 * time.Second)
}

func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOF_END

echo "module example.com/mod" > go.mod

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying slow-function ========================== ${RESET_FORMAT}"
echo

gcloud functions deploy slow-function \
  --gen2 \
  --runtime go116 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --max-instances 4 \
  --quiet

# Transform DEVSHELL_PROJECT_ID and REGION
export spcl_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

# Build the final string
export full_path="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$spcl_project$my_region"

# Append the static part
export full_path="${full_path}slow--function:version_1"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying slow-function in Cloud Run ========================== ${RESET_FORMAT}"
echo

gcloud run deploy slow-function \
--image=$full_path \
--min-instances=1 \
--max-instances=4 \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}NOW${RESET_FORMAT}" "${WHITE_TEXT}${BOLD_TEXT}Check The Score${RESET_FORMAT}" "${GREEN_TEXT}${BOLD_TEXT}Upto Task 6 then Process Next${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Please check the score till Task 6, then Proceed ========================== ${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Have you checked progress till task 6? (Y/N): ${RESET_FORMAT}" response
if [[ "$response" != "Y" && "$response" != "y" ]]; then
  echo "Please complete task 6 before proceeding."
fi

echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

cd min-instances/

SLOW_URL=$(gcloud functions describe slow-function --region $REGION --gen2 --format="value(serviceConfig.uri)")

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Testing slow-function ========================== ${RESET_FORMAT}"
echo

hey -n 10 -c 10 $SLOW_URL

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deleting slow-function from Cloud Run ========================== ${RESET_FORMAT}"
echo

gcloud run services delete slow-function --region $REGION --quiet

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying slow-concurrent-function ========================== ${RESET_FORMAT}"
echo

gcloud functions deploy slow-concurrent-function \
  --gen2 \
  --runtime go116 \
  --entry-point HelloWorld \
  --source . \
  --region $REGION \
  --trigger-http \
  --allow-unauthenticated \
  --min-instances 1 \
  --max-instances 4 \
  --quiet

# Transform DEVSHELL_PROJECT_ID and REGION
export spcl_project=$(echo "$DEVSHELL_PROJECT_ID" | sed 's/-/--/g; s/$/__/g')
export my_region=$(echo "$REGION" | sed 's/-/--/g; s/$/__/g')

# Build the final string
export full_path="$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/gcf-artifacts/$spcl_project$my_region"

# Append the static part
export full_path="${full_path}slow--concurrent--function:version_1"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying slow-concurrent-function in Cloud Run ========================== ${RESET_FORMAT}"
echo
gcloud run deploy slow-concurrent-function \
--image=$full_path \
--concurrency=100 \
--cpu=1 \
--max-instances=4 \
--region=$REGION \
--project=$DEVSHELL_PROJECT_ID \
 && gcloud run services update-traffic slow-concurrent-function --to-latest --region=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Click here: "${RESET_FORMAT}""${BLUE_TEXT}${BOLD_TEXT}"https://console.cloud.google.com/run/deploy/$REGION/slow-concurrent-function?project=$DEVSHELL_PROJECT_ID""${RESET_FORMAT}"

echo

# echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
# echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
# echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
