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
read -p "${YELLOW_TEXT}${BOLD_TEXT} Enter REGION: ${RESET_FORMAT}" REGION
echo "${GREEN_TEXT}${BOLD_TEXT} You Entered : $REGION ${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling the Cloud Run API... Please Wait... ========================== ${RESET_FORMAT}"
echo

gcloud services enable run.googleapis.com

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Cloud Run API enabled. Waiting 10 seconds... ========================== ${RESET_FORMAT}"
echo
sleep 10

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating and Navigating to 'arcadecrew' Directory... ========================== ${RESET_FORMAT}"
echo
mkdir arcadecrew && cd arcadecrew

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating 'index.js' file... ========================== ${RESET_FORMAT}"
echo

cat > index.js <<EOF_END
/**
 * Responds to any HTTP request.
 *
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 */
exports.GCFunction = (req, res) => {
    let message = req.query.message || req.body.message || 'Subscribe to Arcade Crew';
    res.status(200).send(message);
  };
  
EOF_END

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating 'package.json' file... ========================== ${RESET_FORMAT}"
echo
cat > package.json <<EOF_END
{
    "name": "sample-http",
    "version": "0.0.1"
  }
  
EOF_END

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating a Cloud Storage bucket... Please wait ========================== ${RESET_FORMAT}"
echo

gsutil mb -p $DEVSHELL_PROJECT_ID gs://$DEVSHELL_PROJECT_ID

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Bucket created. Waiting 30 seconds... ========================== ${RESET_FORMAT}"
echo
sleep 30

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Getting Project Number... ========================== ${RESET_FORMAT}"
echo

export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="json(projectNumber)" --quiet | jq -r '.projectNumber')

# Set the service account email
SERVICE_ACCOUNT="service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com"

# Get the current IAM policy
IAM_POLICY=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format=json)

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Checking IAM Bindings... ========================== ${RESET_FORMAT}"
echo

# Check if the binding exists
if [[ "$IAM_POLICY" == *"$SERVICE_ACCOUNT"* && "$IAM_POLICY" == *"roles/artifactregistry.reader"* ]]; then
  echo "IAM binding exists for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
else
  echo "IAM binding does not exist for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
  
  # Create the IAM binding
  gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/artifactregistry.reader

  echo "IAM binding created for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
fi

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying the Cloud Function (GCFunction)... Please Wait... ========================== ${RESET_FORMAT}"
echo
gcloud functions deploy GCFunction \
  --region=$REGION \
  --gen2 \
  --trigger-http \
  --runtime=nodejs20 \
  --allow-unauthenticated \
  --max-instances=5

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Calling the Cloud Function (GCFunction)... ========================== ${RESET_FORMAT}"
echo

DATA=$(printf 'Subscribe to Arcade Crew' | base64) && gcloud functions call GCFunction --region=$REGION --data '{"data":"'$DATA'"}'

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Waiting for 50 seconds... ========================== ${RESET_FORMAT}"
echo

sleep 50

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Waiting for 30 seconds... ========================== ${RESET_FORMAT}"
echo
sleep 30
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Re-getting Project Number... ========================== ${RESET_FORMAT}"
echo
export PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format="json(projectNumber)" --quiet | jq -r '.projectNumber')

# Set the service account email
SERVICE_ACCOUNT="service-$PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com"

# Get the current IAM policy
IAM_POLICY=$(gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID --format=json)

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Re-checking IAM Bindings... ========================== ${RESET_FORMAT}"
echo

# Check if the binding exists
if [[ "$IAM_POLICY" == *"$SERVICE_ACCOUNT"* && "$IAM_POLICY" == *"roles/artifactregistry.reader"* ]]; then
  echo "IAM binding exists for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
else
  echo "IAM binding does not exist for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
  
  # Create the IAM binding
  gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role=roles/artifactregistry.reader

  echo "IAM binding created for service account: $SERVICE_ACCOUNT with role roles/artifactregistry.reader"
fi

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Re-deploying the Cloud Function (GCFunction)... Please Wait... ========================== ${RESET_FORMAT}"
echo

gcloud functions deploy GCFunction \
  --region=$REGION \
  --gen2 \
  --trigger-http \
  --runtime=nodejs20 \
  --allow-unauthenticated \
  --max-instances=5

echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Re-calling the Cloud Function (GCFunction)... ========================== ${RESET_FORMAT}"
echo

DATA=$(printf 'Subscribe to Arcade Crew' | base64) && gcloud functions call GCFunction --region=$REGION --data '{"data":"'$DATA'"}'
echo

echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
