#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo ""

read -p "Enter ZONE: " ZONE


gcloud auth list 

gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID \
--format=json >./policy.json

sed -i '/^{/a\   "auditConfigs": [\
      {\
         "service": "allServices",\
         "auditLogConfigs": [\
            { "logType": "ADMIN_READ" },\
            { "logType": "DATA_READ" },\
            { "logType": "DATA_WRITE" }\
         ]\
      }\
   ],' policy.json


gcloud projects set-iam-policy $DEVSHELL_PROJECT_ID \
./policy.json

gcloud logging read \
"logName=projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity \
AND protoPayload.serviceName=storage.googleapis.com \
AND protoPayload.methodName=storage.buckets.delete"

gcloud logging read \
"logName=projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity"

gcloud logging read \
"logName=projects/$DEVSHELL_PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity"

gsutil mb gs://$DEVSHELL_PROJECT_ID
echo "this is a sample file" > sample.txt
gsutil cp sample.txt gs://$DEVSHELL_PROJECT_ID
gcloud compute networks create mynetwork --subnet-mode=auto
gcloud compute instances create default-us-vm \
--machine-type=e2-micro \
--zone=$ZONE --network=mynetwork

gsutil rm -r gs://$DEVSHELL_PROJECT_ID

sleep 30

bq query --use_legacy_sql=false \
'
#standardSQL
SELECT
  timestamp,
  resource.labels.instance_id,
  protopayload_auditlog.authenticationInfo.principalEmail,
  protopayload_auditlog.resourceName,
  protopayload_auditlog.methodName
FROM
 `auditlogs_dataset.cloudaudit_googleapis_com_activity_*`
WHERE
  PARSE_DATE("%Y%m%d", _TABLE_SUFFIX) BETWEEN
  DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND
  CURRENT_DATE()
  AND resource.type = "gce_instance"
  AND operation.first IS TRUE
  AND protopayload_auditlog.methodName = "v1.compute.instances.delete"
ORDER BY
  timestamp,
  resource.labels.instance_id
LIMIT
  1000
'


bq query --use_legacy_sql=false \
'
#standardSQL
SELECT
  timestamp,
  resource.labels.bucket_name,
  protopayload_auditlog.authenticationInfo.principalEmail,
  protopayload_auditlog.resourceName,
  protopayload_auditlog.methodName
FROM
 `auditlogs_dataset.cloudaudit_googleapis_com_activity_*`
WHERE
  PARSE_DATE("%Y%m%d", _TABLE_SUFFIX) BETWEEN
  DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND
  CURRENT_DATE()
  AND resource.type = "gcs_bucket"
  AND protopayload_auditlog.methodName = "storage.buckets.delete"
ORDER BY
  timestamp,
  resource.labels.instance_id
LIMIT
  1000
'
echo ""
# Completion message
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

