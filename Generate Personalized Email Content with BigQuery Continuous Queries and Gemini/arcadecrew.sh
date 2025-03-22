#!/bin/bash

# Define color variables
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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


# Error handling function
function error_exit {
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}" >&2
}

# Success message function
function success_message {
    echo "${GREEN_TEXT}${BOLD_TEXT}SUCCESS: $1${RESET_FORMAT}"
}

# Info message function
function info_message {
    echo "${BLUE_TEXT}${BOLD_TEXT}INFO: $1${RESET_FORMAT}"
}

# Warning message function
function warning_message {
    echo "${YELLOW_TEXT}${BOLD_TEXT}WARNING: $1${RESET_FORMAT}"
}

# Manual step function
function manual_step {
    echo "${MAGENTA_TEXT}${BOLD_TEXT}MANUAL STEP REQUIRED: $1${RESET_FORMAT}"
}

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    error_exit "Project ID not found. Make sure you're authenticated."
fi

info_message "Starting lab automation for project: $PROJECT_ID"
info_message "Current date and time: $(date)"

# Set region (using default region from the lab)
REGION="us-central1"
info_message "Using region: $REGION"

# Define custom service account
CUSTOM_SA="bq-continuous-query-sa@${PROJECT_ID}.iam.gserviceaccount.com"

echo "${CYAN_TEXT}${BOLD_TEXT}========== TASK 1: Create and configure a BigQuery ML remote model ==========${RESET_FORMAT}"

# Create BigQuery remote connection
info_message "Creating BigQuery remote connection for Vertex AI..."
bq mk --connection --location=$REGION \
    --project_id=$PROJECT_ID \
    --connection_type=CLOUD_RESOURCE \
    continuous-queries-connection || error_exit "Failed to create BigQuery connection"

success_message "BigQuery connection created successfully"

# Get the BigQuery connection service account
info_message "Getting BigQuery connection service account..."
BQ_SA=$(bq show --connection $PROJECT_ID.$REGION.continuous-queries-connection | grep "serviceAccountId" | cut -d: -f2- | tr -d ' "')

if [ -z "$BQ_SA" ]; then
    error_exit "Failed to get BigQuery service account"
fi

success_message "Retrieved BigQuery service account: $BQ_SA"

# Grant Vertex AI User role to the BigQuery service account
info_message "Granting Vertex AI User role to BigQuery service account..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${BQ_SA}" \
    --role="roles/aiplatform.user" || error_exit "Failed to grant Vertex AI User role"

success_message "Granted Vertex AI User role to BigQuery service account"

# Create BigQuery ML remote model
info_message "Creating BigQuery ML remote model (gemini_1_5_pro)..."
bq query --nouse_legacy_sql \
    "CREATE MODEL IF NOT EXISTS \`${PROJECT_ID}.continuous_queries.gemini_1_5_pro\`
    REMOTE WITH CONNECTION \`${REGION}.continuous-queries-connection\`
    OPTIONS(endpoint = 'gemini-1.5-pro');" || error_exit "Failed to create BigQuery ML model"

success_message "Created BigQuery ML remote model successfully"

echo "${CYAN_TEXT}${BOLD_TEXT}========== TASK 2: Grant a custom service account access to BigQuery and Pub/Sub resources ==========${RESET_FORMAT}"

# Grant BigQuery Connection User role to custom service account
info_message "Granting BigQuery Connection User role to custom service account ($CUSTOM_SA)..."
gcloud iam service-accounts add-iam-policy-binding $BQ_SA \
    --member="serviceAccount:${CUSTOM_SA}" \
    --role="roles/bigquery.connectionUser" || error_exit "Failed to grant BigQuery Connection User role"

success_message "Granted BigQuery Connection User role to custom service account"

# Grant BigQuery Data Editor role to custom service account for the dataset
info_message "Granting BigQuery Data Editor role to custom service account for the dataset..."
bq add-iam-policy-binding \
    --member="serviceAccount:${CUSTOM_SA}" \
    --role="roles/bigquery.dataEditor" \
    continuous_queries || error_exit "Failed to grant BigQuery Data Editor role"

success_message "Granted BigQuery Data Editor role to custom service account for dataset"

# Grant Pub/Sub Viewer and Publisher roles to custom service account
info_message "Granting Pub/Sub Viewer and Publisher roles to custom service account..."
gcloud pubsub topics add-iam-policy-binding recapture_customer \
    --member="serviceAccount:${CUSTOM_SA}" \
    --role="roles/pubsub.viewer" || error_exit "Failed to grant Pub/Sub Viewer role"

gcloud pubsub topics add-iam-policy-binding recapture_customer \
    --member="serviceAccount:${CUSTOM_SA}" \
    --role="roles/pubsub.publisher" || error_exit "Failed to grant Pub/Sub Publisher role"

success_message "Granted Pub/Sub Viewer and Publisher roles to custom service account"

echo "${CYAN_TEXT}${BOLD_TEXT}========== TASK 3: Create and configure an Application Integration trigger ==========${RESET_FORMAT}"

# Enable required APIs for Application Integration
info_message "Enabling APIs for Application Integration..."
gcloud services enable integrations.googleapis.com || warning_message "Failed to enable integrations API, it may already be enabled"
gcloud services enable connectors.googleapis.com || warning_message "Failed to enable connectors API, it may already be enabled"
gcloud services enable connectors-api.googleapis.com || warning_message "Failed to enable connectors-api API, it may already be enabled"

manual_step "Application Integration requires manual configuration through the Console UI:"
manual_step "1. Go to Application Integration in the Google Cloud Console"
manual_step "2. Select region '$REGION'"
manual_step "3. Click 'Quick setup' to enable necessary APIs"
manual_step "4. Create an integration named 'abandoned-shopping-carts-integration'"
manual_step "5. Add a Pub/Sub trigger with topic: projects/$PROJECT_ID/topics/recapture_customer"
manual_step "6. Select the service account: $CUSTOM_SA"
manual_step "7. Add Data Mapping task with the following variables:"
manual_step "   - message_output (from CloudPubSubMessage.data)"
manual_step "   - customer_message (from CloudPubSubMessage.data with JSON functions)"
manual_step "   - customer_email (from CloudPubSubMessage.data with JSON functions)"
manual_step "   - customer_name (from CloudPubSubMessage.data with JSON functions)"
manual_step "8. Add Send Email task connected to Data Mapping with:"
manual_step "   - To: customer_email variable"
manual_step "   - Subject: Don't forget the items in your cart"
manual_step "   - Body Format: HTML"
manual_step "   - Body: customer_message variable"
manual_step "9. Publish the integration"

echo "${CYAN_TEXT}${BOLD_TEXT}========== TASK 4: Create a continuous query in BigQuery that generates email text with Gemini ==========${RESET_FORMAT}"

# Create BigQuery Enterprise reservation
info_message "Creating BigQuery Enterprise reservation..."
bq mk \
    --project_id=$PROJECT_ID \
    --location=$REGION \
    --reservation \
    --slots=50 \
    --edition=ENTERPRISE \
    bq-continuous-queries-reservation || error_exit "Failed to create BigQuery reservation"

success_message "Created BigQuery Enterprise reservation"

# Create assignment
info_message "Creating reservation assignment..."
bq mk \
    --project_id=$PROJECT_ID \
    --location=$REGION \
    --reservation_assignment \
    --assignee_type=PROJECT \
    --assignee_id=$PROJECT_ID \
    --job_type=CONTINUOUS \
    --reservation_id=bq-continuous-queries-reservation || error_exit "Failed to create assignment"

success_message "Created reservation assignment"

# Create the continuous query in BigQuery
info_message "Setting up continuous query..."

# The query needs to be saved to a file due to its complexity
QUERY_FILE=$(mktemp)
cat <<EOF > $QUERY_FILE
EXPORT DATA
 OPTIONS (format = CLOUD_PUBSUB,
 uri = "https://pubsub.googleapis.com/projects/${PROJECT_ID}/topics/recapture_customer")
AS (SELECT
   TO_JSON_STRING(
     STRUCT(
       customer_name AS customer_name,
       customer_email AS customer_email, REGEXP_REPLACE(REGEXP_EXTRACT(ml_generate_text_llm_result,r"(?im)\<html\>(?s:.)*\<\/html\>"), r"(?i)\[your name\]", "Your friends at AI Megastore") AS customer_message)),
 FROM ML.GENERATE_TEXT( MODEL \`${PROJECT_ID}.continuous_queries.gemini_1_5_pro\`,
     (SELECT
       customer_name,
       customer_email,
       CONCAT("Write an email to customer ", customer_name, ", explaining the benefits and encouraging them to complete their purchase of: ", products, ". Also show other items the customer might be interested in. Provide the response email in HTML format.") AS prompt
     FROM
          APPENDS(TABLE \`${PROJECT_ID}.continuous_queries.abandoned_carts\`,
            -- Configure the APPENDS TVF start_timestamp to specify when you want to
            -- Start processing data using your continuous query.
            -- Here we process data as ten minutes before the current time.
            CURRENT_TIMESTAMP() - INTERVAL 10 MINUTE)),
   STRUCT( 1024 AS max_output_tokens,
     0.2 AS temperature,
     1 AS candidate_count, 
     TRUE AS flatten_json_output)))
EOF

manual_step "The continuous query requires manual setup through the BigQuery UI:"
manual_step "1. Go to BigQuery Studio in Google Cloud Console"
manual_step "2. Create a new query and paste the following query:"
manual_step "$(cat $QUERY_FILE)"
manual_step "3. Click the gear icon and select 'Continuous query'"
manual_step "4. Click 'Confirm' if prompted"
manual_step "5. Click the gear icon again and select 'Query settings'"
manual_step "6. Under 'Continuous query', select the service account: $CUSTOM_SA"
manual_step "7. Click 'Save' to exit settings"
manual_step "8. Click 'Run' to start the continuous query"
manual_step "9. Wait until you see 'Job running continuously' at the top of the query window"

rm $QUERY_FILE

echo "${CYAN_TEXT}${BOLD_TEXT}========== TASK 5: Add data to the abandoned carts table to test the continuous query ==========${RESET_FORMAT}"

# Testing the continuous query by adding data
info_message "Creating test data for the abandoned carts table..."

# Insert data to trigger the workflow
info_message "Inserting test data into the abandoned_carts table..."
bq query --nouse_legacy_sql \
    "INSERT INTO \`${PROJECT_ID}.continuous_queries.abandoned_carts\`(customer_name, customer_email, products)
    VALUES (\"${USER:-Gourav9165}\", \"$(whoami)@example.com\", \"Violin Strings, Tiny Saxophone, Guitar Strap\")" || \
    error_exit "Failed to insert test data"

success_message "Inserted test data into abandoned_carts table successfully"
success_message "The workflow should now process this data and send an email"

echo

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
