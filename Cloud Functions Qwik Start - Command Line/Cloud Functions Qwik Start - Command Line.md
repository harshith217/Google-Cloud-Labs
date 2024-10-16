# Cloud Functions: Qwik Start - Command Line 
### LAB: [GSP080](https://www.cloudskillsboost.google/focuses/916?parent=catalog) 

Watch the full video walkthrough:  
[![YouTube Solution](https://img.shields.io/badge/YouTube-Watch%20Solution-red?style=flat&logo=youtube)](https://www.youtube.com/watch?v=wjSrI-UHmM8)

---

### Run In Cloud Shell

```
export REGION=
```

```
#!/bin/bash

BG_RED=`tput setab 1`
TEXT_GREEN=`tput setab 2`
TEXT_RED=`tput setaf 1`

BOLD=`tput bold`
RESET=`tput sgr0`


echo "${BG_RED}${BOLD}Starting Execution${RESET}"

gcloud config set compute/region $REGION

mkdir gcf_hello_world && cd $_

cat > index.js <<'EOF_END'
const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback with the Functions Framework that will
// be executed when the Pub/Sub trigger topic receives a message.
functions.cloudEvent('helloPubSub', cloudEvent => {
  // The Pub/Sub message is passed as the CloudEvent's data payload.
  const base64name = cloudEvent.data.message.data;

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World';

  console.log(`Hello, ${name}!`);
});
EOF_END

cat > package.json <<'EOF_END'
{
  "name": "gcf_hello_world",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF_END

npm install

gcloud services disable cloudfunctions.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

sleep 15

gcloud functions deploy nodejs-pubsub-function \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=helloPubSub \
  --trigger-topic cf-demo \
  --stage-bucket $DEVSHELL_PROJECT_ID-bucket \
  --service-account cloudfunctionsa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
  --allow-unauthenticated \
  --quiet

gcloud functions describe nodejs-pubsub-function \
  --region=$REGION

echo -e "${TEXT_RED}${BOLD}Congratulations For Completing The Lab !!! ${RESET}"
echo -e "${TEXT_GREEN}${BOLD}Subscribe to our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET}"
```

---

### 🏆 Congratulations!!! You completed the Lab! 🎉

---

### **Join the Community!**

- [Whatsapp Group](https://chat.whatsapp.com/FbVg9NI6Dp4CzfdsYmy0AE)  

[![Arcade Crew Channel](https://img.shields.io/badge/YouTube-Arcade%20Crew-red?style=flat&logo=youtube)](https://www.youtube.com/@Arcade61432)

---