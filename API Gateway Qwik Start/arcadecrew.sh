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

echo "${YELLOW_TEXT}${BOLD_TEXT} Enter REGION: ${RESET_FORMAT}"
read -r REGION
export REGION=$REGION
export PROJECT_ID=$(gcloud config get-value project)

gcloud config set compute/region $REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling Services ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Enabling apigateway.googleapis.com and run.googleapis.com services... ${RESET_FORMAT}"

gcloud services enable apigateway.googleapis.com --project $DEVSHELL_PROJECT_ID
gcloud services enable run.googleapis.com

echo "${YELLOW_TEXT}${BOLD_TEXT} Waiting for 15 seconds for services to be enabled... ${RESET_FORMAT}"
sleep 15

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Adding IAM Policy Bindings ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Adding IAM policy binding for serviceusage.serviceUsageAdmin... ${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"

echo "${YELLOW_TEXT}${BOLD_TEXT} Adding IAM policy binding for artifactregistry.reader... ${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/artifactregistry.reader"

echo "${YELLOW_TEXT}${BOLD_TEXT} Waiting for 30 seconds for IAM policies to be applied... ${RESET_FORMAT}"
sleep 30

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Cloning Node.js Samples ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Cloning the Google Cloud Platform Node.js samples repository... ${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git

cd nodejs-docs-samples/functions/helloworld/helloworldGet

echo "${YELLOW_TEXT}${BOLD_TEXT} Waiting for 60 seconds before deploying the function... ${RESET_FORMAT}"
sleep 60

deploy_function() {
  gcloud functions deploy helloGET \
    --runtime nodejs20 \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated
}

deploy_success=false

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Deploying Cloud Function ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Attempting to deploy the 'helloGET' Cloud Function... ${RESET_FORMAT}"

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${GREEN_TEXT}${BOLD_TEXT} Cloud Run service is created. Exiting the loop. ${RESET_FORMAT}"
    deploy_success=true
  else
    echo "${RED_TEXT}${BOLD_TEXT} Waiting for Cloud Run service to be created... Retrying in 60 seconds. ${RESET_FORMAT}"
    sleep 60
  fi
done

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Verifying Deployment ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Describing the deployed 'helloGET' function... ${RESET_FORMAT}"
gcloud functions describe helloGET --region $REGION

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Testing Function ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Sending a test request to the deployed function... ${RESET_FORMAT}"
curl -v https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET

cd ~

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating openapi2-functions.yaml ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating 'openapi2-functions.yaml' file... ${RESET_FORMAT}"

cat > openapi2-functions.yaml <<EOF_CP
# openapi2-functions.yaml
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://us-east4-qwiklabs-gcp-01-b47a65687b9f.cloudfunctions.net/helloGET
      responses:
       '200':
          description: A successful response
          schema:
            type: string
EOF_CP

export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Modifying openapi2-functions.yaml ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Replacing placeholder values in 'openapi2-functions.yaml'... ${RESET_FORMAT}"
sed -i "s/API_ID/${API_ID}/g" openapi2-functions.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions.yaml

export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"
echo "${BLUE_TEXT}${BOLD_TEXT} Generated API ID: $API_ID ${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating API and API Config ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating API 'hello-world-api'... ${RESET_FORMAT}"
gcloud api-gateway apis create "hello-world-api"  --project=$PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT} Creating API config 'hello-world-config'... ${RESET_FORMAT}"
gcloud api-gateway api-configs create hello-world-config --project=$PROJECT_ID --api=$API_ID --openapi-spec=openapi2-functions.yaml --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating Gateway ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating gateway 'hello-gateway'... ${RESET_FORMAT}"
gcloud api-gateway gateways create hello-gateway --location=$REGION --project=$PROJECT_ID --api=$API_ID --api-config=hello-world-config

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating API Key ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating API key with display name 'awesome'... ${RESET_FORMAT}"
gcloud alpha services api-keys create --display-name="awesome"

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

echo "${BLUE_TEXT}${BOLD_TEXT} API Key: $API_KEY ${RESET_FORMAT}"

MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r .[0].managedService | cut -d'/' -f6)
echo "${BLUE_TEXT}${BOLD_TEXT} Managed Service: $MANAGED_SERVICE ${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling Managed Service ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Enabling the managed service... ${RESET_FORMAT}"
gcloud services enable $MANAGED_SERVICE

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating openapi2-functions2.yaml ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating 'openapi2-functions2.yaml' file... ${RESET_FORMAT}"
cat > openapi2-functions2.yaml <<EOF_CP
# openapi2-functions.yaml
swagger: '2.0'
info:
  title: API_ID description
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user
      operationId: hello
      x-google-backend:
        address: https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET
      security:
        - api_key: []
      responses:
       '200':
          description: A successful response
          schema:
            type: string
securityDefinitions:
  api_key:
    type: "apiKey"
    name: "key"
    in: "query"
EOF_CP

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Modifying openapi2-functions2.yaml ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Replacing placeholder values in 'openapi2-functions2.yaml'... ${RESET_FORMAT}"
sed -i "s/API_ID/${API_ID}/g" openapi2-functions2.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions2.yaml

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Creating Second API Config ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Creating API config 'hello-config'... ${RESET_FORMAT}"
gcloud api-gateway api-configs create hello-config --project=$PROJECT_ID \
  --display-name="Hello Config" --api=$API_ID --openapi-spec=openapi2-functions2.yaml \
  --backend-auth-service-account=$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Updating Gateway ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Updating gateway 'hello-gateway' with the new config... ${RESET_FORMAT}"
gcloud api-gateway gateways update hello-gateway --location=$REGION --project=$PROJECT_ID --api=$API_ID --api-config=hello-config

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Adding More IAM Policy Bindings ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Adding IAM policy binding for service account... ${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_ID@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"

echo "${YELLOW_TEXT}${BOLD_TEXT} Adding another IAM policy binding for compute service account... ${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"


MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r --arg api_id "$API_ID" '.[] | select(.name | endswith($api_id)) | .managedService' | cut -d'/' -f6)
echo "${BLUE_TEXT}${BOLD_TEXT} Managed Service: $MANAGED_SERVICE ${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Enabling Managed Service (Again) ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Enabling the managed service again... ${RESET_FORMAT}"
gcloud services enable $MANAGED_SERVICE


export GATEWAY_URL=$(gcloud api-gateway gateways describe hello-gateway --location $REGION --format json | jq -r .defaultHostname)

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Testing Gateway (Without API Key) ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Sending a test request to the gateway (without API key)... ${RESET_FORMAT}"
curl -sL $GATEWAY_URL/hello

echo
echo "${GREEN_TEXT}${BOLD_TEXT} ========================== Testing Gateway (With API Key) ========================== ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT} Sending a test request to the gateway (with API key)... ${RESET_FORMAT}"
curl -sL -w "\n" $GATEWAY_URL/hello?key=$API_KEY
echo

echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
