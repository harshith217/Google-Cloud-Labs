# Define color codes
YELLOW='\033[0;33m'
BG_RED=`tput setab 1`
TEXT_GREEN=`tput setab 2`
TEXT_RED=`tput setaf 1`

BOLD=`tput bold`
RESET=`tput sgr0`

NC='\033[0m'

echo "${BG_RED}${BOLD}Starting Execution${RESET}"

# Prompt the user for the location input
echo -e "${YELLOW}${BOLD}Please enter the region/location (Region):${RESET}"
read LOCATION

# Define variables
export GEO_CODE_REQUEST_PUBSUB_TOPIC=geocode_request
export PROCESSOR_NAME=form-parser
export PROJECT_ID=$(gcloud config get-value core/project)
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

# Fetch the API key by its display name
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome-key")
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# Create directories and download files from Google Cloud Storage
mkdir -p ./documentai-pipeline-demo
gsutil -m cp -r gs://sureskills-lab-dev/gsp927/documentai-pipeline-demo/* ~/documentai-pipeline-demo/

# Set up the Document AI processor
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR_NAME"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/processors"

# Create Cloud Storage buckets for input/output/archived invoices
gsutil mb -c standard -l ${LOCATION} -b on gs://${PROJECT_ID}-input-invoices
gsutil mb -c standard -l ${LOCATION} -b on gs://${PROJECT_ID}-output-invoices
gsutil mb -c standard -l ${LOCATION} -b on gs://${PROJECT_ID}-archived-invoices

# Create BigQuery datasets and tables
bq --location="US" mk -d --description "Form Parser Results" ${PROJECT_ID}:invoice_parser_results
cd ~/documentai-pipeline-demo/scripts/table-schema/
bq mk --table invoice_parser_results.doc_ai_extracted_entities doc_ai_extracted_entities.json
bq mk --table invoice_parser_results.geocode_details geocode_details.json

# Set up Pub/Sub topics
gcloud pubsub topics create ${GEO_CODE_REQUEST_PUBSUB_TOPIC}

# Deploy Cloud Functions for processing invoices
deploy_function() {
  gcloud functions deploy process-invoices \
    --region=${LOCATION} \
    --entry-point=process_invoice \
    --runtime=python37 \
    --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
    --source=cloud-functions/process-invoices \
    --timeout=400 \
    --env-vars-file=cloud-functions/process-invoices/.env.yaml \
    --trigger-resource=gs://${PROJECT_ID}-input-invoices \
    --trigger-event=google.storage.object.finalize
}

deploy_success=false
while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 30
  fi
done

echo "Moving to the next deployment..."

# Deploy Cloud Functions for geocoding addresses
deploy_function() {
  gcloud functions deploy geocode-addresses \
    --region=${LOCATION} \
    --entry-point=process_address \
    --runtime=python38 \
    --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
    --source=cloud-functions/geocode-addresses \
    --timeout=60 \
    --env-vars-file=cloud-functions/geocode-addresses/.env.yaml \
    --trigger-topic=${GEO_CODE_REQUEST_PUBSUB_TOPIC}
}

deploy_success=false
while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Cloud Run service is created. Exiting the loop."
    deploy_success=true
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 30
  fi
done

echo "Proceeding with processor setup..."

# Retrieve processor ID from Document AI
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/[a-z0-9-]+\/processors\/([^"]+)".*/\1/')

export PROCESSOR_ID

# Re-deploy functions with processor details
gcloud functions deploy process-invoices \
  --region=${LOCATION} \
  --entry-point=process_invoice \
  --runtime=python37 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize \
  --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=${LOCATION}

gcloud functions deploy geocode-addresses \
  --region=${LOCATION} \
  --entry-point=process_address \
  --runtime=python38 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/geocode-addresses \
  --timeout=60 \
  --trigger-topic=${GEO_CODE_REQUEST_PUBSUB_TOPIC} \
  --update-env-vars=API_KEY=${API_KEY}

# Upload sample files to Cloud Storage
gsutil cp gs://sureskills-lab-dev/gsp927/documentai-pipeline-demo/sample-files/* gs://${PROJECT_ID}-input-invoices/
  
# Final message
echo -e "${TEXT_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"
echo -e "${TEXT_GREEN}${BOLD}Subscribe to our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET}"
