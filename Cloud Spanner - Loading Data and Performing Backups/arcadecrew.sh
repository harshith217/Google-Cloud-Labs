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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Verifying authenticated gcloud accounts...${RESET_FORMAT}"
gcloud auth list

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⚙️  Fetching default Google Cloud zone and region...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}Could not automatically fetch the default zone.${RESET_FORMAT}"
  read -p "${CYAN_TEXT}Please enter your Zone: ${RESET_FORMAT}" ZONE
fi
echo "${GREEN_TEXT}Using Zone: ${BOLD_TEXT}$ZONE${RESET_FORMAT}"

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  if [ -n "$ZONE" ]; then
    REGION=$(echo "$ZONE" | sed 's/-[a-z]$//') # Derive region from zone by removing the last part (e.g., -a)
    echo "${GREEN_TEXT}Derived Region from Zone: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
  else
    echo "${YELLOW_TEXT}Could not automatically fetch or derive the default region.${RESET_FORMAT}"
    read -p "${CYAN_TEXT}Please enter your Region: ${RESET_FORMAT}" REGION
  fi
fi
echo "${GREEN_TEXT}Using Region: ${BOLD_TEXT}$REGION${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Setting the default compute region in gcloud configuration...${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Retrieving and setting the Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_ID=$DEVSHELL_PROJECT_ID
echo "${GREEN_TEXT}Project ID set to: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📝 Inserting a single customer record into Spanner using gcloud CLI...${RESET_FORMAT}"
gcloud spanner databases execute-sql banking-db --instance=banking-instance \
 --sql="INSERT INTO Customer (CustomerId, Name, Location) VALUES ('bdaaaa97-1b4b-4e58-b4ad-84030de92235', 'Richard Nelson', 'Ada Ohio')"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🐍 Creating Python script (insert.py) for single record insertion...${RESET_FORMAT}"
cat > insert.py <<EOF_CP
from google.cloud import spanner
from google.cloud.spanner_v1 import param_types

INSTANCE_ID = "banking-instance"
DATABASE_ID = "banking-db"

spanner_client = spanner.Client()
instance = spanner_client.instance(INSTANCE_ID)
database = instance.database(DATABASE_ID)

def insert_customer(transaction):
  row_ct = transaction.execute_update(
    "INSERT INTO Customer (CustomerId, Name, Location)"
    "VALUES ('b2b4002d-7813-4551-b83b-366ef95f9273', 'Shana Underwood', 'Ely Iowa')"
  )
  print("{} record(s) inserted.".format(row_ct))

database.run_in_transaction(insert_customer)

EOF_CP
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Python script 'insert.py' created successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}▶️  Executing 'insert.py' to add a customer via Python Client Library...${RESET_FORMAT}"
python3 insert.py

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Pausing for 60 seconds...${RESET_FORMAT}"
for i in $(seq 60 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT} $i seconds remaining...${RESET_FORMAT}\r"
  sleep 1
done
echo -ne "\n" # Move to the next line after the countdown

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🐍 Creating Python script (batch_insert.py) for batch record insertion...${RESET_FORMAT}"
cat > batch_insert.py <<EOF_CP
from google.cloud import spanner
from google.cloud.spanner_v1 import param_types

INSTANCE_ID = "banking-instance"
DATABASE_ID = "banking-db"

spanner_client = spanner.Client()
instance = spanner_client.instance(INSTANCE_ID)
database = instance.database(DATABASE_ID)

with database.batch() as batch:
  batch.insert(
    table="Customer",
    columns=("CustomerId", "Name", "Location"),
    values=[
    ('edfc683f-bd87-4bab-9423-01d1b2307c0d', 'John Elkins', 'Roy Utah'),
    ('1f3842ca-4529-40ff-acdd-88e8a87eb404', 'Martin Madrid', 'Ames Iowa'),
    ('3320d98e-6437-4515-9e83-137f105f7fbc', 'Theresa Henderson', 'Anna Texas'),
    ('6b2b2774-add9-4881-8702-d179af0518d8', 'Norma Carter', 'Bend Oregon'),

    ],
  )

print("Rows inserted")
EOF_CP
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Python script 'batch_insert.py' created successfully.${RESET_FORMAT}"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}▶️  Executing 'batch_insert.py' to add multiple customers...${RESET_FORMAT}"
python3 batch_insert.py

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Pausing for 60 seconds...${RESET_FORMAT}"
for i in $(seq 60 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT} $i seconds remaining...${RESET_FORMAT}\r"
  sleep 1
done
echo -ne "\n" # Move to the next line after the countdown

echo
echo "${CYAN_TEXT}${BOLD_TEXT}☁️  Creating a Google Cloud Storage bucket...${RESET_FORMAT}"
echo "${YELLOW_TEXT}Bucket name will be: ${BOLD_TEXT}gs://$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
gsutil mb gs://$DEVSHELL_PROJECT_ID

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📄 Creating an empty file and uploading to the bucket for Dataflow staging...${RESET_FORMAT}"
touch emptyfile
gsutil cp emptyfile gs://$DEVSHELL_PROJECT_ID/tmp/emptyfile
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Empty file uploaded to gs://$DEVSHELL_PROJECT_ID/tmp/emptyfile${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔄 Ensuring Dataflow API is enabled (disable then enable)...${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This step might take a moment.${RESET_FORMAT}"
gcloud services disable dataflow.googleapis.com --force
gcloud services enable dataflow.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Dataflow API re-enabled.${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Pausing for 90 seconds to allow API changes to propagate...${RESET_FORMAT}"
for i in $(seq 90 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT} $i seconds remaining...${RESET_FORMAT}\r"
  sleep 1
done
echo -ne "\n" # Move to the next line after the countdown

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🚀 Launching Dataflow job to load data from GCS to Spanner...${RESET_FORMAT}"
echo "${YELLOW_TEXT}Job Name: ${BOLD_TEXT}spanner-load${RESET_FORMAT}"
echo "${YELLOW_TEXT}Template Region: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo "${YELLOW_TEXT}Staging Location: ${BOLD_TEXT}gs://$DEVSHELL_PROJECT_ID/tmp/${RESET_FORMAT}"
gcloud dataflow jobs run spanner-load --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_Cloud_Spanner --region $REGION --staging-location gs://$DEVSHELL_PROJECT_ID/tmp/ --parameters instanceId=banking-instance,databaseId=banking-db,importManifest=gs://cloud-training/OCBL372/manifest.json

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Monitor your Dataflow Job status here:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/dataflow/jobs?referrer=search&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
