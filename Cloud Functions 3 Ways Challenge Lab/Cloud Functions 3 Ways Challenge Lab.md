# Cloud Functions: 3 Ways: Challenge Lab

### LAB: [ARC104](https://www.cloudskillsboost.google/focuses/61974?parent=catalog)

## 🚀 **Solution Walkthrough**

Watch the full video walkthrough:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=pnACDbYxD-g)

---

### Run In Cloud Shell
```
export HTTP_FUNCTION=
export FUNCTION_NAME=
export REGION=
```

```
#!/bin/bash

BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
TEXT_RED=`tput setaf 1`

BOLD=`tput bold`
RESET=`tput sgr0`

echo "${BG_RED}${BOLD}Starting Execution${RESET}"

gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com

sleep 30

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$DEVSHELL_PROJECT_ID" --format='value(project_number)')

SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

gsutil mb -l $REGION gs://$DEVSHELL_PROJECT_ID

export BUCKET="gs://$DEVSHELL_PROJECT_ID"

mkdir ~/$FUNCTION_NAME && cd $_
touch index.js && touch package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.cloudEvent('$FUNCTION_NAME', (cloudevent) => {
  console.log('A new event in your Cloud Storage bucket has been logged!');
  console.log(cloudevent);
});
EOF

cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_cloud_storage_function() {
  gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime nodejs16 \
  --entry-point $FUNCTION_NAME \
  --source . \
  --region $REGION \
  --trigger-bucket $BUCKET \
  --trigger-location $REGION \
  --max-instances 2 \
  --quiet
}

# Loop until the Cloud Storage function is created
while true; do
  deploy_cloud_storage_function

  if gcloud run services describe $FUNCTION_NAME --region $REGION &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done

cd ..

mkdir ~/HTTP_FUNCTION && cd $_
touch index.js && touch package.json

cat > index.js <<EOF
const functions = require('@google-cloud/functions-framework');
functions.http('$HTTP_FUNCTION', (req, res) => {
  res.status(200).send('awesome lab');
});
EOF


cat > package.json <<EOF
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOF

deploy_http_function() {
  gcloud functions deploy $HTTP_FUNCTION \
  --gen2 \
  --runtime nodejs16 \
  --entry-point $HTTP_FUNCTION \
  --source . \
  --region $REGION \
  --trigger-http \
  --timeout 600s \
  --max-instances 2 \
  --min-instances 1 \
  --quiet
}

# Loop until the HTTP function is created
while true; do
  deploy_http_function

  if gcloud run services describe $HTTP_FUNCTION --region $REGION &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done

# Final success message
echo -e "${TEXT_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"
echo -e "${BG_GREEN}${BOLD}Subscribe to our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET}"

```

---

### 🏆 Congratulations!!! You completed the Lab! 🎉

---

### **Join the Community!**

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---
