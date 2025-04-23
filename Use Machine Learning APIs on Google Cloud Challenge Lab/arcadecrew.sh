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

read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}🌐 Enter the LANGUAGE: ${RESET_FORMAT}")" LANGUAGE
read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}📍 Enter the LOCALE: ${RESET_FORMAT}")" LOCAL
read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}📊 Enter the BIGQUERY_ROLE: ${RESET_FORMAT}")" BIGQUERY_ROLE
read -p "$(echo -e "${YELLOW_TEXT}${BOLD_TEXT}☁️ Enter the CLOUD_STORAGE_ROLE: ${RESET_FORMAT}")" CLOUD_STORAGE_ROLE
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}✨ Creating new service account 'sample-sa'...${RESET_FORMAT}"
gcloud iam service-accounts create sample-sa
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}🔐 Assigning necessary IAM roles...${RESET_FORMAT}"
echo -e "${CYAN_TEXT}  ➡️ BigQuery Role: ${WHITE_TEXT}${BOLD_TEXT}$BIGQUERY_ROLE${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$BIGQUERY_ROLE

echo -e "${CYAN_TEXT}  ➡️ Cloud Storage Role: ${WHITE_TEXT}${BOLD_TEXT}$CLOUD_STORAGE_ROLE${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=$CLOUD_STORAGE_ROLE

echo -e "${CYAN_TEXT}  ➡️ Service Usage Consumer Role${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID --member=serviceAccount:sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com --role=roles/serviceusage.serviceUsageConsumer
echo ""

echo -e "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting 2 minutes for IAM changes to take effect...${RESET_FORMAT}"
for i in {1..120}; do
    echo -ne "${YELLOW_TEXT}⏱️ ${i}/120 seconds elapsed...\r${RESET_FORMAT}"
    sleep 1
done
echo -e "\n"

echo -e "${BLUE_TEXT}${BOLD_TEXT}🔑 Generating service account key file...${RESET_FORMAT}"
gcloud iam service-accounts keys create sample-sa-key.json --iam-account sample-sa@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/sample-sa-key.json
echo -e "${GREEN_TEXT}✅ Key generated and GOOGLE_APPLICATION_CREDENTIALS set.${RESET_FORMAT}"
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}📥 Downloading the image analysis Python script...${RESET_FORMAT}"
wget https://raw.githubusercontent.com/guys-in-the-cloud/cloud-skill-boosts/main/Challenge-labs/Integrate%20with%20Machine%20Learning%20APIs%3A%20Challenge%20Lab/analyze-images-v2.py
echo -e "${GREEN_TEXT}✅ Script download complete.${RESET_FORMAT}"
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}✏️ Modifying script locale setting to ${WHITE_TEXT}${BOLD_TEXT}${LOCAL}${BLUE_TEXT}${BOLD_TEXT}...${RESET_FORMAT}"
sed -i "s/'en'/'${LOCAL}'/g" analyze-images-v2.py
echo -e "${GREEN_TEXT}✅ Locale successfully updated in the script.${RESET_FORMAT}"
echo

echo -e "${BLUE_TEXT}${BOLD_TEXT}🤖 Executing the image analysis script...${RESET_FORMAT}"
python3 analyze-images-v2.py
python3 analyze-images-v2.py $DEVSHELL_PROJECT_ID $DEVSHELL_PROJECT_ID
echo -e "${GREEN_TEXT}✅ Image analysis script finished.${RESET_FORMAT}"
echo

echo -e "${BOLD_CYAN}🔍 Querying BigQuery for locale distribution...${RESET_FORMAT}"
bq query --use_legacy_sql=false "SELECT locale,COUNT(locale) as lcount FROM image_classification_dataset.image_text_detail GROUP BY locale ORDER BY lcount DESC"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
