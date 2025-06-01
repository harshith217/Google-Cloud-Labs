#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
BG_RED=$'\033[41m'
BG_GREEN=$'\033[42m'
BG_YELLOW=$'\033[43m'
BG_BLUE=$'\033[44m'
BG_MAGENTA=$'\033[45m'
BG_CYAN=$'\033[46m'
BG_WHITE=$'\033[47m'
DIM_TEXT=$'\033[2m'
BLINK_TEXT=$'\033[5m'
REVERSE_TEXT=$'\033[7m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo -n -e "${YELLOW_TEXT}${BOLD_TEXT}Enter the BIGQUERY DATASET name:${RESET_FORMAT} "
read DATASET
export DATASET
echo
echo -n -e "${YELLOW_TEXT}${BOLD_TEXT}Enter the CLOUD STORAGE BUCKET name:${RESET_FORMAT} "
read BUCKET
export BUCKET
echo
echo -n -e "${YELLOW_TEXT}${BOLD_TEXT}Enter the TABLE name:${RESET_FORMAT} "
read TABLE
export TABLE
echo
echo -n -e "${YELLOW_TEXT}${BOLD_TEXT}Enter the BUCKET_URL_1 value:${RESET_FORMAT} "
read BUCKET_URL_1
export BUCKET_URL_1
echo
echo -n -e "${YELLOW_TEXT}${BOLD_TEXT}Enter the BUCKET_URL_2 value:${RESET_FORMAT} "
read BUCKET_URL_2
export BUCKET_URL_2
echo

echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 🔧 STEP 1: API SERVICES ACTIVATION 🔧 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Activating the API Keys service for your Google Cloud project...${RESET_FORMAT}"
gcloud services enable apikeys.googleapis.com

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🔑 STEP 2: API KEY CREATION 🔑 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Generating a new API key with the display name 'arcadecrew'...${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="arcadecrew" 

echo
echo "${BG_YELLOW}${WHITE_TEXT}${BOLD_TEXT} 🔍 STEP 3: API KEY RETRIEVAL 🔍 ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the API key name from your project...${RESET_FORMAT}"
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=arcadecrew")

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 🗝️ STEP 4: API KEY STRING EXTRACTION 🗝️ ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Extracting the API key string for authentication...${RESET_FORMAT}"
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 🌍 STEP 5: REGION CONFIGURATION 🌍 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Determining your default Google Cloud region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo
echo "${BG_RED}${WHITE_TEXT}${BOLD_TEXT} 🆔 STEP 6: PROJECT ID DISCOVERY 🆔 ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Obtaining your current project identifier...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🔢 STEP 7: PROJECT NUMBER LOOKUP 🔢 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Retrieving your project number for resource management...${RESET_FORMAT}"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber')

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 📊 STEP 8: BIGQUERY DATASET CREATION 📊 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Setting up your BigQuery dataset for data storage...${RESET_FORMAT}"
bq mk $DATASET

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 🪣 STEP 9: CLOUD STORAGE BUCKET SETUP 🪣 ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a new Cloud Storage bucket for file storage...${RESET_FORMAT}"
gsutil mb gs://$BUCKET

echo
echo "${BG_YELLOW}${WHITE_TEXT}${BOLD_TEXT} 📁 STEP 10: LAB FILES DOWNLOAD 📁 ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading required lab files from Google Cloud Storage...${RESET_FORMAT}"
gsutil cp gs://cloud-training/gsp323/lab.csv  .
gsutil cp gs://cloud-training/gsp323/lab.schema .

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 👀 STEP 11: SCHEMA INSPECTION 👀 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Examining the current schema structure...${RESET_FORMAT}"
cat lab.schema

echo
echo "${RED_TEXT}${BOLD_TEXT}📝 Generating the correct schema format for BigQuery table...${RESET_FORMAT}"
echo '[
    {"type":"STRING","name":"guid"},
    {"type":"BOOLEAN","name":"isActive"},
    {"type":"STRING","name":"firstname"},
    {"type":"STRING","name":"surname"},
    {"type":"STRING","name":"company"},
    {"type":"STRING","name":"email"},
    {"type":"STRING","name":"phone"},
    {"type":"STRING","name":"address"},
    {"type":"STRING","name":"about"},
    {"type":"TIMESTAMP","name":"registered"},
    {"type":"FLOAT","name":"latitude"},
    {"type":"FLOAT","name":"longitude"}
]' > lab.schema

echo
echo "${BG_RED}${WHITE_TEXT}${BOLD_TEXT} 🗂️ STEP 12: BIGQUERY TABLE CREATION 🗂️ ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Creating a new BigQuery table with the defined schema...${RESET_FORMAT}"
bq mk --table $DATASET.$TABLE lab.schema

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🌊 STEP 13: DATAFLOW JOB EXECUTION 🌊 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Launching Dataflow job to transfer data into BigQuery...${RESET_FORMAT}"
gcloud dataflow jobs run arcadecrew-jobs --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery --region $REGION --worker-machine-type e2-standard-2 --staging-location gs://$DEVSHELL_PROJECT_ID-marking/temp --parameters inputFilePattern=gs://cloud-training/gsp323/lab.csv,JSONPath=gs://cloud-training/gsp323/lab.schema,outputTable=$DEVSHELL_PROJECT_ID:$DATASET.$TABLE,bigQueryLoadingTemporaryDirectory=gs://$DEVSHELL_PROJECT_ID-marking/bigquery_temp,javascriptTextTransformGcsPath=gs://cloud-training/gsp323/lab.js,javascriptTextTransformFunctionName=transform

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 🔐 STEP 14: IAM PERMISSIONS ASSIGNMENT 🔐 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring IAM roles for the compute service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin"

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 👤 STEP 15: USER ROLE ASSIGNMENT 👤 ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Granting necessary roles to your user account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/storage.objectViewer

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 🌐 STEP 16: VPC NETWORK CONFIGURATION 🌐 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Enabling private Google access for the default subnet...${RESET_FORMAT}"
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access

echo
echo "${BG_RED}${WHITE_TEXT}${BOLD_TEXT} 👥 STEP 17: SERVICE ACCOUNT CREATION 👥 ${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}Creating a dedicated service account for Natural Language processing...${RESET_FORMAT}"
gcloud iam service-accounts create arcadecrew \
  --display-name "my natural language service account"

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for service account setup to complete...${RESET_FORMAT}"
for i in {15..1}; do
    echo -ne "\r${CYAN_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}"
    sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Service account setup completed!${RESET_FORMAT}     "

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🔑 STEP 18: SERVICE ACCOUNT KEY GENERATION 🔑 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Generating authentication key for the service account...${RESET_FORMAT}"
gcloud iam service-accounts keys create ~/key.json \
  --iam-account arcadecrew@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for service account key generation to complete...${RESET_FORMAT}"
for i in {15..1}; do
    echo -ne "\r${CYAN_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}"
    sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Service account key generation completed!${RESET_FORMAT}     "

echo
echo "${BG_YELLOW}${WHITE_TEXT}${BOLD_TEXT} ⚡ STEP 19: SERVICE ACCOUNT ACTIVATION ⚡ ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Activating the service account for authentication...${RESET_FORMAT}"
export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for service account activation to complete...${RESET_FORMAT}"
for i in {30..1}; do
    echo -ne "\r${CYAN_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}"
    sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Service account activation completed!${RESET_FORMAT}     "

gcloud auth activate-service-account arcadecrew@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --key-file=$GOOGLE_APPLICATION_CREDENTIALS

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 🧠 STEP 20: ML ENTITY ANALYSIS 🧠 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Performing Natural Language entity analysis on sample text...${RESET_FORMAT}"
gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result.json

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🔓 STEP 21: AUTHENTICATION RENEWAL 🔓 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Re-authenticating to Google Cloud without browser launch...${RESET_FORMAT}"
echo
gcloud auth login --no-launch-browser --quiet

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 📤 STEP 22: RESULT UPLOAD 📤 ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Uploading entity analysis results to Cloud Storage...${RESET_FORMAT}"
gsutil cp result.json $BUCKET_URL_2

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📋 Creating request configuration for Speech-to-Text API...${RESET_FORMAT}"
cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-training/gsp323/task3.flac"
  }
}
EOF

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 🎤 STEP 23: SPEECH RECOGNITION PROCESSING 🎤 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Converting audio to text using Speech-to-Text API...${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🚀 STEP 24: SPEECH RESULT UPLOAD 🚀 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Storing speech recognition results in Cloud Storage...${RESET_FORMAT}"
gsutil cp result.json $BUCKET_URL_1

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 🛠️ STEP 25: QUICKSTART SERVICE ACCOUNT 🛠️ ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Setting up a new service account named 'quickstart'...${RESET_FORMAT}"
gcloud iam service-accounts create quickstart

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for quickstart service account setup to complete...${RESET_FORMAT}"
for i in {15..1}; do
    echo -ne "\r${CYAN_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}"
    sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Quickstart service account setup completed!${RESET_FORMAT}     "

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 🗝️ STEP 26: QUICKSTART KEY CREATION 🗝️ ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Generating authentication key for quickstart service account...${RESET_FORMAT}"
gcloud iam service-accounts keys create key.json --iam-account quickstart@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for quickstart service account key generation to complete...${RESET_FORMAT}"
for i in {15..1}; do
    echo -ne "\r${CYAN_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}"
    sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Quickstart service account key generation completed!${RESET_FORMAT}     "

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 🔄 STEP 27: SERVICE ACCOUNT SWITCH 🔄 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Switching to the quickstart service account for authentication...${RESET_FORMAT}"
gcloud auth activate-service-account --key-file key.json

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 📹 STEP 28: VIDEO API REQUEST SETUP 📹 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Preparing request configuration for Video Intelligence API...${RESET_FORMAT}"
cat > request.json <<EOF 
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "TEXT_DETECTION"
   ]
}
EOF

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 🎬 STEP 29: VIDEO ANNOTATION REQUEST 🎬 ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Submitting video for text detection analysis...${RESET_FORMAT}"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 📊 STEP 30: VIDEO ANALYSIS RESULTS 📊 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Retrieving video annotation operation results...${RESET_FORMAT}"
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN" 'https://videointelligence.googleapis.com/v1/operations/OPERATION_FROM_PREVIOUS_REQUEST' > result1.json

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for video annotation processing to complete...${RESET_FORMAT}"
for i in {30..1}; do
    echo -ne "\r${CYAN_TEXT}${BOLD_TEXT}⏳ ${i} seconds remaining...${RESET_FORMAT}"
    sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}✅ Video annotation processing completed!${RESET_FORMAT}     "

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 🔁 STEP 31: SPEECH RECOGNITION RETRY 🔁 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Re-running speech recognition for verification...${RESET_FORMAT}"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🎥 STEP 32: VIDEO ANNOTATION RETRY 🎥 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Re-submitting video annotation request for consistency...${RESET_FORMAT}"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 📋 STEP 33: FINAL VIDEO RESULTS 📋 ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Collecting final video annotation operation results...${RESET_FORMAT}"
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN" 'https://videointelligence.googleapis.com/v1/operations/OPERATION_FROM_PREVIOUS_REQUEST' > result1.json

function check_progress {
    while true; do
        echo
        echo -n "${BOLD_TEXT}${BG_YELLOW}${BLACK_TEXT} Have you checked your progress for Task 3 & Task 4? (Y/N): ${RESET_FORMAT} "
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD_TEXT}${BG_GREEN}${WHITE_TEXT} ✅ Great! Proceeding to the next steps... ✅ ${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD_TEXT}${BG_RED}${WHITE_TEXT} ❌ Please check your progress for Task 3 & Task 4 and then press Y to continue. ❌ ${RESET_FORMAT}"
        else
            echo
            echo "${BOLD_TEXT}${BG_MAGENTA}${WHITE_TEXT} ⚠️ Invalid input. Please enter Y or N. ⚠️ ${RESET_FORMAT}"
        fi
    done
}

echo
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚦      CHECK PROGRESS FOR TASK 3 & 4      🚦${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

check_progress

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🔐 STEP 34: AUTHENTICATION RENEWAL 🔐 ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Re-authenticating to Google Cloud for Dataproc operations...${RESET_FORMAT}"
echo
gcloud auth login --no-launch-browser --quiet

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} ⚡ STEP 35: DATAPROC CLUSTER DEPLOYMENT ⚡ ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Launching a new Dataproc cluster for big data processing...${RESET_FORMAT}"
gcloud dataproc clusters create arcadecrew --enable-component-gateway --region $REGION --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID

echo
echo "${BG_GREEN}${WHITE_TEXT}${BOLD_TEXT} 🖥️ STEP 36: VM INSTANCE DISCOVERY 🖥️ ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Identifying the virtual machine instance in your project...${RESET_FORMAT}"
VM_NAME=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format=json | jq -r '.[0].name')

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} 🌍 STEP 37: VM ZONE IDENTIFICATION 🌍 ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Determining the compute zone of your virtual machine...${RESET_FORMAT}"
export ZONE=$(gcloud compute instances list $VM_NAME --format 'csv[no-heading](zone)')

echo
echo "${BG_BLUE}${WHITE_TEXT}${BOLD_TEXT} 📂 STEP 38: HDFS DATA TRANSFER 📂 ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Copying training data to HDFS on the virtual machine...${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="hdfs dfs -cp gs://cloud-training/gsp323/data.txt /data.txt"

echo
echo "${BG_CYAN}${WHITE_TEXT}${BOLD_TEXT} 💾 STEP 39: LOCAL STORAGE COPY 💾 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}Downloading data to local storage on the virtual machine...${RESET_FORMAT}"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="gsutil cp gs://cloud-training/gsp323/data.txt /data.txt"

echo
echo "${BG_MAGENTA}${WHITE_TEXT}${BOLD_TEXT} ⚡ STEP 40: SPARK JOB SUBMISSION ⚡ ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing PageRank algorithm using Apache Spark on Dataproc...${RESET_FORMAT}"
gcloud dataproc jobs submit spark \
  --cluster=arcadecrew \
  --region=$REGION \
  --class=org.apache.spark.examples.SparkPageRank \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  --project=$DEVSHELL_PROJECT_ID \
  -- /data.txt

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
