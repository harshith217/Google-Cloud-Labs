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

#Instructions
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 1: Setting Region and Zone ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Extracting default region and zone from project metadata.${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

PROJECT_ID=`gcloud config get-value project`
PROJECT=`gcloud config get-value project`

echo "${GREEN_TEXT}${BOLD_TEXT}  Region: $REGION${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Zone: $ZONE${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}  Project ID: $PROJECT_ID${RESET_FORMAT}"

# Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 2: Enabling Cloud Run API ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Enabling the Cloud Run API for the project.${RESET_FORMAT}"

gcloud services enable run.googleapis.com

# Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 3: Creating Artifact Registry Repository ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Creating a Docker repository named 'helloworld-repo' in Artifact Registry.${RESET_FORMAT}"

gcloud artifacts repositories create helloworld-repo --location=$REGION --repository-format=docker --project=$PROJECT

# Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 4: Creating the helloworld Application ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Creating a directory and navigating into it for the 'helloworld' application.${RESET_FORMAT}"
mkdir helloworld
cd helloworld

echo "${WHITE_TEXT}  Creating 'package.json' file.${RESET_FORMAT}"
cat > package.json <<'EOF_END'
{
  "name": "helloworld",
  "description": "Simple hello world sample in Node",
  "version": "1.0.0",
  "private": true,
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "engines": {
    "node": ">=12.0.0"
  },
  "author": "Google LLC",
  "license": "Apache-2.0",
  "dependencies": {
    "express": "^4.17.1"
  }
}
EOF_END

echo "${BLUE_TEXT}  Creating 'index.js' file.${RESET_FORMAT}"
cat > index.js <<'EOF_END'
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  const name = process.env.NAME || 'World';
  res.send(`Hello ${name}!`);
});

const port = parseInt(process.env.PORT) || 8080;
app.listen(port, () => {
  console.log(`helloworld: listening on port ${port}`);
});
EOF_END

# Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 5: Building and Pushing the Docker Image ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Building a Docker image and pushing it to the created repository.${RESET_FORMAT}"

gcloud builds submit --pack image=$REGION-docker.pkg.dev/$PROJECT/helloworld-repo/helloworld

# Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}  Step 6: Setting up Cloud Run Deployment ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Creating a directory for Cloud Run deployment files.${RESET_FORMAT}"

mkdir ~/deploy-cloudrun
cd ~/deploy-cloudrun

echo "${WHITE_TEXT}  Creating 'skaffold.yaml' file.${RESET_FORMAT}"
cat > skaffold.yaml <<'EOF_END'
apiVersion: skaffold/v3alpha1
kind: Config
metadata:
  name: deploy-run-quickstart
profiles:
- name: dev
  manifests:
    rawYaml:
    - run-dev.yaml
- name: prod
  manifests:
    rawYaml:
    - run-prod.yaml
deploy:
  cloudrun: {}
EOF_END

echo "${WHITE_TEXT}  Creating 'run-dev.yaml' file.${RESET_FORMAT}"
cat > run-dev.yaml <<'EOF_END'
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-dev
spec:
  template:
    spec:
      containers:
      - image: my-app-image
EOF_END

echo "${WHITE_TEXT}  Creating 'run-prod.yaml' file.${RESET_FORMAT}"
cat > run-prod.yaml <<'EOF_END'
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: helloworld-prod
spec:
  template:
    spec:
      containers:
      - image: my-app-image
EOF_END

echo "${WHITE_TEXT}  Creating 'clouddeploy.yaml' file.${RESET_FORMAT}"
cat > clouddeploy.yaml <<EOF_END
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
 name: my-run-demo-app-1
description: main application pipeline
serialPipeline:
 stages:
 - targetId: run-dev
   profiles: [dev]
 - targetId: run-prod
   profiles: [prod]
---
  
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: run-dev
description: Cloud Run development service
run:
 location: projects/$PROJECT_ID/locations/$REGION
---

apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
 name: run-prod
description: Cloud Run production service
run:
 location: projects/$PROJECT_ID/locations/$REGION
EOF_END
#Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Step 7: Applying Cloud Deploy Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT} Deploying to dev first ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Applying the Cloud Deploy configuration from 'clouddeploy.yaml'.${RESET_FORMAT}"
#get user permission
read -r -p "Are you want to apply Cloud Deploy configuration? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  echo "y" | gcloud deploy apply --file clouddeploy.yaml --region=$REGION
else
  echo "${RED_TEXT}${BOLD_TEXT}  Cloud Deploy configuration not applied.${RESET_FORMAT}"
fi

#Instructions
echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Step 8: Creating and Promoting the Release${RESET_FORMAT}"
echo "${WHITE_TEXT} Creating Release now ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Creating a release for the Cloud Run deployment.${RESET_FORMAT}"

#get user permission
read -r -p "Are you want to create release? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  gcloud deploy releases create run-release-001 --project=$PROJECT --region=$REGION --delivery-pipeline=my-run-demo-app-1 --images=my-app-image="$REGION-docker.pkg.dev/$PROJECT/helloworld-repo/helloworld"
else
  echo "${RED_TEXT}${BOLD_TEXT}  Release is not created.${RESET_FORMAT}"
fi
echo "${WHITE_TEXT} Promoting Release now ${RESET_FORMAT}"
echo "${WHITE_TEXT}  Promoting the release to the production target.${RESET_FORMAT}"

#get user permission
read -r -p "Are you want to promote the release? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  echo "y" | gcloud deploy releases promote --release=run-release-001 --delivery-pipeline=my-run-demo-app-1 --region=$REGION --to-target=run-prod
else
  echo "${RED_TEXT}${BOLD_TEXT}  Release is not promoted.${RESET_FORMAT}"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
