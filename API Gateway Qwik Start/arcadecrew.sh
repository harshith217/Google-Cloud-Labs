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

# Clear the screen
clear

# Print the welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Instruction for REGION input
read -p "${CYAN_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
export REGION

# Instruction for PROJECT_ID
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the current project ID from gcloud configuration.${RESET_FORMAT}"
echo

export PROJECT_ID=$(gcloud config get-value project)

# Instruction for setting compute region
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting the compute region for the project.${RESET_FORMAT}"
echo

gcloud config set compute/region $REGION

# Enabling required services
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required services: API Gateway and Cloud Run.${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take a few moments.${RESET_FORMAT}"
echo

gcloud services enable apigateway.googleapis.com --project $DEVSHELL_PROJECT_ID
gcloud services enable run.googleapis.com

sleep 15

# Fetching project number
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the project number for IAM policy bindings.${RESET_FORMAT}"
echo

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Adding IAM policy bindings
echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy bindings for required roles.${RESET_FORMAT}"
echo

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/serviceusage.serviceUsageAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role="roles/artifactregistry.reader"

sleep 30

# Cloning the repository
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the Node.js sample repository.${RESET_FORMAT}"
echo

git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git

cd nodejs-docs-samples/functions/helloworld/helloworldGet

sleep 60

# Deploying the function
echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying the Cloud Function.${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take some time. Please wait...${RESET_FORMAT}"
echo

deploy_function() {
  gcloud functions deploy helloGET \
    --runtime nodejs20 \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated
}

deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Run service is created. Exiting the loop.${RESET_FORMAT}"
    deploy_success=true
  else
    echo "${RED_TEXT}${BOLD_TEXT}Waiting for Cloud Run service to be created...${RESET_FORMAT}"
    sleep 60
  fi
done

echo "${GREEN_TEXT}${BOLD_TEXT}Running the next code...${RESET_FORMAT}"

gcloud functions describe helloGET --region $REGION

curl -v https://$REGION-$PROJECT_ID.cloudfunctions.net/helloGET

cd ~

# Creating OpenAPI spec
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the OpenAPI specification file.${RESET_FORMAT}"
echo

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

sed -i "s/API_ID/${API_ID}/g" openapi2-functions.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" openapi2-functions.yaml

export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z' | fold -w ${1:-8} | head -n 1)"
echo $API_ID

# Creating API Gateway
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the API Gateway.${RESET_FORMAT}"
echo

gcloud api-gateway apis create "hello-world-api"  --project=$PROJECT_ID

gcloud api-gateway api-configs create hello-world-config --project=$PROJECT_ID --api=$API_ID --openapi-spec=openapi2-functions.yaml --backend-auth-service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

gcloud api-gateway gateways create hello-gateway --location=$REGION --project=$PROJECT_ID --api=$API_ID --api-config=hello-world-config

# Creating API key
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating an API key for the gateway.${RESET_FORMAT}"
echo

gcloud alpha services api-keys create --display-name="awesome"  

KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome") 

export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)") 

echo $API_KEY

# Enabling managed service
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling the managed service for the API Gateway.${RESET_FORMAT}"
echo

MANAGED_SERVICE=$(gcloud api-gateway apis list --format json | jq -r .[0].managedService | cut -d'/' -f6)
echo $MANAGED_SERVICE

gcloud services enable $MANAGED_SERVICE

# Testing the API Gateway
echo "${YELLOW_TEXT}${BOLD_TEXT}Testing the API Gateway endpoints.${RESET_FORMAT}"
echo

export GATEWAY_URL=$(gcloud api-gateway gateways describe hello-gateway --location $REGION --format json | jq -r .defaultHostname)
curl -sL $GATEWAY_URL/hello

curl -sL -w "\n" $GATEWAY_URL/hello?key=$API_KEY

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}            LAB COMPLETED!             ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"

# Subscription message
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"