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
echo "${BLUE_TEXT}${BOLD_TEXT}========================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}          INITIATING EXECUTION...       ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}========================================${RESET_FORMAT}"
echo

# Instruction for REGION input
read -p "${CYAN_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION
export REGION
echo
# Removed API_KEY prompt here, it will be generated later

# Instruction for PROJECT_ID
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the current project ID from gcloud configuration.${RESET_FORMAT}"
echo
export PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve Project ID. Please ensure gcloud is configured correctly.${RESET_FORMAT}"
  exit 1
fi
echo "${GREEN_TEXT}Using Project ID: ${PROJECT_ID}${RESET_FORMAT}"
echo

# Instruction for setting compute region
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting the compute region to '$REGION' for the project.${RESET_FORMAT}"
echo
gcloud config set compute/region $REGION --quiet
echo

# Enabling required services
echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling required services: API Gateway, Cloud Run, Service Usage, Artifact Registry.${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take a few moments.${RESET_FORMAT}"
echo
gcloud services enable apigateway.googleapis.com --project $PROJECT_ID
gcloud services enable run.googleapis.com --project $PROJECT_ID
gcloud services enable serviceusage.googleapis.com --project $PROJECT_ID
gcloud services enable artifactregistry.googleapis.com --project $PROJECT_ID
sleep 5 # Short sleep after enabling services

# Fetching project number
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the project number for IAM policy bindings.${RESET_FORMAT}"
echo
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
if [ -z "$PROJECT_NUMBER" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve Project Number.${RESET_FORMAT}"
  exit 1
fi
echo "${GREEN_TEXT}Using Project Number: ${PROJECT_NUMBER}${RESET_FORMAT}"
export GCE_SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
echo

# Adding IAM policy bindings
echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy bindings for the Compute Engine default service account.${RESET_FORMAT}"
echo "${CYAN_TEXT}Binding roles/serviceusage.serviceUsageAdmin...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:${GCE_SERVICE_ACCOUNT}" --role="roles/serviceusage.serviceUsageAdmin" --condition=None --quiet
echo "${CYAN_TEXT}Binding roles/artifactregistry.reader...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:${GCE_SERVICE_ACCOUNT}" --role="roles/artifactregistry.reader" --condition=None --quiet
sleep 5 # Short sleep after IAM changes

# Cloning the repository
if [ ! -d "nodejs-docs-samples" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the Node.js sample repository.${RESET_FORMAT}"
  echo
  git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Node.js sample repository already cloned.${RESET_FORMAT}"
  echo
fi

# Navigate to function directory
if [ -d "nodejs-docs-samples/functions/helloworld/helloworldGet" ]; then
  cd nodejs-docs-samples/functions/helloworld/helloworldGet
else
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not find the function directory nodejs-docs-samples/functions/helloworld/helloworldGet.${RESET_FORMAT}"
  exit 1
fi

sleep 2 # Short sleep after cd

# Deploying the function
echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying the Cloud Function 'helloGET'.${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take some time. Please wait...${RESET_FORMAT}"
echo

deploy_function() {
  gcloud functions deploy helloGET \
    --runtime nodejs20 \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated \
    --gen2 \
    --quiet # Added --gen2 as it's often preferred, and --quiet
}

# Check if function already exists
if gcloud functions describe helloGET --region $REGION --format="value(name)" &>/dev/null; then
   echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Function 'helloGET' already exists. Skipping deployment.${RESET_FORMAT}"
else
  deploy_success=false
  retries=3
  count=0
  while [ "$deploy_success" = false ] && [ $count -lt $retries ]; do
    if deploy_function; then
      echo "${GREEN_TEXT}${BOLD_TEXT}Cloud Function 'helloGET' deployed successfully.${RESET_FORMAT}"
      deploy_success=true
    else
      count=$((count+1))
      echo "${RED_TEXT}${BOLD_TEXT}Function deployment failed (Attempt $count/$retries). Retrying in 60 seconds...${RESET_FORMAT}"
      sleep 60
    fi
  done

  if [ "$deploy_success" = false ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: Failed to deploy Cloud Function after $retries attempts. Exiting.${RESET_FORMAT}"
    exit 1
  fi
fi
echo

# Get Function URL
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching Cloud Function URL.${RESET_FORMAT}"
FUNCTION_URL=$(gcloud functions describe helloGET --region $REGION --format='value(httpsTrigger.url)')
if [ -z "$FUNCTION_URL" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve Function URL.${RESET_FORMAT}"
  exit 1
fi
echo "${GREEN_TEXT}Function URL: ${FUNCTION_URL}${RESET_FORMAT}"
echo

# Test direct function invocation
echo "${YELLOW_TEXT}${BOLD_TEXT}Testing direct Cloud Function invocation.${RESET_FORMAT}"
curl -sfw "\n" $FUNCTION_URL || echo "${RED_TEXT}Direct function test failed (this might be okay if Function requires auth later).${RESET_FORMAT}"
echo

# Navigate back to home directory
cd ~

# --- Task 1-3 Parts (API, Initial Config, Gateway Creation) ---

echo
echo "${BLUE_TEXT}${BOLD_TEXT}--- Initial API Gateway Setup (Tasks 1-3) ---${RESET_FORMAT}"
echo

# Generate a unique ID for the API
export API_ID="hello-world-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)"
echo "${GREEN_TEXT}Using API ID: ${API_ID}${RESET_FORMAT}"

# Create Initial OpenAPI spec (Unsecured)
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the initial OpenAPI specification file (openapi2-functions-unsecured.yaml).${RESET_FORMAT}"
echo
cat > openapi2-functions-unsecured.yaml <<EOF_UNSECURE
# openapi2-functions-unsecured.yaml
swagger: '2.0'
info:
  title: ${API_ID} description (Unsecured)
  description: Sample API on API Gateway with a Google Cloud Functions backend
  version: 1.0.0
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user (Unsecured)
      operationId: hello
      x-google-backend:
        address: ${FUNCTION_URL} # Use the fetched function URL directly
      responses:
       '200':
          description: A successful response
          schema:
            type: string
EOF_UNSECURE
echo "${GREEN_TEXT}Initial OpenAPI spec created.${RESET_FORMAT}"
echo

# Define API and Config Names
export API_NAME="hello-world-api" # Consistent API name
export INITIAL_CONFIG_ID="hello-config-initial"
export GATEWAY_ID="hello-gateway"

# Create API
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the API '${API_NAME}'.${RESET_FORMAT}"
echo
if ! gcloud api-gateway apis describe $API_NAME --project=$PROJECT_ID &>/dev/null; then
  gcloud api-gateway apis create $API_NAME --project=$PROJECT_ID --quiet
  echo "${GREEN_TEXT}API '${API_NAME}' created.${RESET_FORMAT}"
else
  echo "${GREEN_TEXT}API '${API_NAME}' already exists.${RESET_FORMAT}"
fi
echo

# Create Initial API Config
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the initial API Config '${INITIAL_CONFIG_ID}'.${RESET_FORMAT}"
echo
if ! gcloud api-gateway api-configs describe $INITIAL_CONFIG_ID --api=$API_NAME --project=$PROJECT_ID &>/dev/null; then
  gcloud api-gateway api-configs create $INITIAL_CONFIG_ID \
    --project=$PROJECT_ID \
    --api=$API_NAME \
    --openapi-spec=openapi2-functions-unsecured.yaml \
    --backend-auth-service-account=$GCE_SERVICE_ACCOUNT \
    --display-name="Hello Initial Config" \
    --quiet
  echo "${GREEN_TEXT}Initial API Config '${INITIAL_CONFIG_ID}' created.${RESET_FORMAT}"
else
   echo "${GREEN_TEXT}Initial API Config '${INITIAL_CONFIG_ID}' already exists.${RESET_FORMAT}"
fi
echo

# Create API Gateway
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the API Gateway '${GATEWAY_ID}'.${RESET_FORMAT}"
echo
if ! gcloud api-gateway gateways describe $GATEWAY_ID --location=$REGION --project=$PROJECT_ID &>/dev/null; then
  gcloud api-gateway gateways create $GATEWAY_ID \
    --location=$REGION \
    --project=$PROJECT_ID \
    --api=$API_NAME \
    --api-config=$INITIAL_CONFIG_ID \
    --quiet
  echo "${GREEN_TEXT}API Gateway '${GATEWAY_ID}' created. Waiting for deployment...${RESET_FORMAT}"
  sleep 90 # Gateways can take a while to become active
else
  echo "${GREEN_TEXT}API Gateway '${GATEWAY_ID}' already exists.${RESET_FORMAT}"
  # Even if it exists, give it time if the script was just run
  echo "${CYAN_TEXT}Waiting a bit for existing gateway to be stable...${RESET_FORMAT}"
  sleep 30
fi
echo

# --- Task 4: Secure access using an API key ---

echo
echo "${BLUE_TEXT}${BOLD_TEXT}--- Securing Access with API Key (Task 4) ---${RESET_FORMAT}"
echo

# Create API key
# Note: The lab asks to create this manually first. This script automates it.
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating an API key (display name: 'gateway-key').${RESET_FORMAT}"
echo
# Check if key exists first
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter="displayName=gateway-key" --limit=1)

if [ -z "$KEY_NAME" ]; then
  # Create the key - use alpha for programmatic creation
  echo "${CYAN_TEXT}No existing key found. Creating...${RESET_FORMAT}"
  gcloud alpha services api-keys create --display-name="gateway-key" --project=$PROJECT_ID --quiet
  sleep 10 # Give time for the key creation to propagate
  KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter="displayName=gateway-key" --limit=1)
  if [ -z "$KEY_NAME" ]; then
     echo "${RED_TEXT}${BOLD_TEXT}Error: Failed to create or find API Key 'gateway-key'.${RESET_FORMAT}"
     exit 1
  fi
  echo "${GREEN_TEXT}API Key created.${RESET_FORMAT}"
else
  echo "${GREEN_TEXT}API Key 'gateway-key' already exists.${RESET_FORMAT}"
fi

# Get the key string
echo "${YELLOW_TEXT}${BOLD_TEXT}Retrieving the API key string.${RESET_FORMAT}"
export API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")
if [ -z "$API_KEY" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve API Key string.${RESET_FORMAT}"
  exit 1
fi
# Mask the key in output, just show confirmation
echo "${GREEN_TEXT}API Key string retrieved and stored in \$API_KEY variable.${RESET_FORMAT}"
# echo "API Key: $API_KEY" # Uncomment carefully if you need to see the key

# Get Managed Service Name and Enable it (enables API Key support)
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching managed service name and enabling it for API Key support.${RESET_FORMAT}"
MANAGED_SERVICE=$(gcloud api-gateway apis describe $API_NAME --project=$PROJECT_ID --format='value(managedService)')

if [ -z "$MANAGED_SERVICE" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve Managed Service name for API '$API_NAME'.${RESET_FORMAT}"
  # Attempt to list and guess if describe failed
  MANAGED_SERVICE=$(gcloud services list --enabled --filter="name:*.apigateway.${PROJECT_ID}.cloud.goog" --format='value(config.name)' --limit=1)
  if [ -z "$MANAGED_SERVICE" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}Could not determine managed service. Exiting.${RESET_FORMAT}"
      exit 1
  else
      echo "${YELLOW_TEXT}Warning: Had to guess managed service: $MANAGED_SERVICE ${RESET_FORMAT}"
  fi
fi

echo "${GREEN_TEXT}Using Managed Service: ${MANAGED_SERVICE}${RESET_FORMAT}"
gcloud services enable $MANAGED_SERVICE --project=$PROJECT_ID --quiet
echo "${GREEN_TEXT}Managed service enabled (or already enabled).${RESET_FORMAT}"
echo

# Create NEW OpenAPI spec with API Key security
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the new OpenAPI specification with API key security (openapi2-functions-secured.yaml).${RESET_FORMAT}"
echo
cat > openapi2-functions-secured.yaml <<EOF_SECURE
# openapi2-functions-secured.yaml
swagger: '2.0'
info:
  title: ${API_ID} description (Secured)
  description: Sample API on API Gateway with a Google Cloud Functions backend, requiring API Key
  version: 1.0.1 # Increment version
schemes:
  - https
produces:
  - application/json
paths:
  /hello:
    get:
      summary: Greet a user (Secured)
      operationId: hello
      x-google-backend:
        address: ${FUNCTION_URL} # Use the fetched function URL directly
      # Add security requirement
      security:
        - api_key: []
      responses:
       '200':
          description: A successful response
          schema:
            type: string
# Add security definition for API Key
securityDefinitions:
  api_key:
    type: "apiKey"
    name: "key" # Expects key in query param named 'key'
    in: "query"
EOF_SECURE
echo "${GREEN_TEXT}Secured OpenAPI spec created.${RESET_FORMAT}"
echo

# --- Task 5: Create and deploy a new API config ---

echo
echo "${BLUE_TEXT}${BOLD_TEXT}--- Create and Deploy Secured API Config (Task 5) ---${RESET_FORMAT}"
echo

# Define Secured Config Name
export SECURED_CONFIG_ID="hello-config-secured"

# Create New (Secured) API Config
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating the new secured API Config '${SECURED_CONFIG_ID}'.${RESET_FORMAT}"
echo
if ! gcloud api-gateway api-configs describe $SECURED_CONFIG_ID --api=$API_NAME --project=$PROJECT_ID &>/dev/null; then
  gcloud api-gateway api-configs create $SECURED_CONFIG_ID \
    --project=$PROJECT_ID \
    --api=$API_NAME \
    --openapi-spec=openapi2-functions-secured.yaml \
    --backend-auth-service-account=$GCE_SERVICE_ACCOUNT \
    --display-name="Hello Secured Config" \
    --quiet
  echo "${GREEN_TEXT}Secured API Config '${SECURED_CONFIG_ID}' created.${RESET_FORMAT}"
else
   echo "${GREEN_TEXT}Secured API Config '${SECURED_CONFIG_ID}' already exists.${RESET_FORMAT}"
fi
echo

# Update the Gateway to use the new Secured Config
echo "${YELLOW_TEXT}${BOLD_TEXT}Updating API Gateway '${GATEWAY_ID}' to use secured config '${SECURED_CONFIG_ID}'.${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}This may take a few minutes...${RESET_FORMAT}"
echo
gcloud api-gateway gateways update $GATEWAY_ID \
  --location=$REGION \
  --project=$PROJECT_ID \
  --api=$API_NAME \
  --api-config=$SECURED_CONFIG_ID \
  --quiet

# Wait for the gateway update to complete
sleep 90
echo "${GREEN_TEXT}Gateway update command issued. Allowing time for changes to apply.${RESET_FORMAT}"
echo

# --- Task 6: Testing calls using your API key ---

echo
echo "${BLUE_TEXT}${BOLD_TEXT}--- Testing Gateway Access With/Without Key (Task 6) ---${RESET_FORMAT}"
echo

# Get Gateway URL (might be the same, but good practice to re-fetch)
echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the API Gateway URL.${RESET_FORMAT}"
export GATEWAY_URL=$(gcloud api-gateway gateways describe $GATEWAY_ID --location $REGION --project=$PROJECT_ID --format='value(defaultHostname)')
if [ -z "$GATEWAY_URL" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Error: Could not retrieve Gateway hostname.${RESET_FORMAT}"
  exit 1
fi
# Ensure GATEWAY_URL includes https:// for curl
if [[ ! $GATEWAY_URL == https://* ]]; then
    export GATEWAY_URL="https://$GATEWAY_URL"
fi
echo "${GREEN_TEXT}Gateway URL: ${GATEWAY_URL}${RESET_FORMAT}"
echo

# Test WITHOUT API Key (Expect Failure)
echo "${YELLOW_TEXT}${BOLD_TEXT}Testing access WITHOUT API key (expecting an UNAUTHENTICATED error):${RESET_FORMAT}"
echo "Command: curl -sL ${GATEWAY_URL}/hello"
curl -sL ${GATEWAY_URL}/hello || echo -e "\n${GREEN_TEXT}(Expected error received)${RESET_FORMAT}"
echo
echo

# Test WITH API Key (Expect Success)
echo "${YELLOW_TEXT}${BOLD_TEXT}Testing access WITH API key (expecting 'Hello World!'):${RESET_FORMAT}"
echo "Command: curl -sL -w \"\\n\" ${GATEWAY_URL}/hello?key=\$API_KEY"
curl_output=$(curl -sL -w "\n%{http_code}" "${GATEWAY_URL}/hello?key=${API_KEY}")
http_code=$(echo "$curl_output" | tail -n1)
content=$(echo "$curl_output" | sed '$d') # Get all but the last line

echo "Response Content: $content"
echo "HTTP Status Code: $http_code"

if [[ "$http_code" == "200" ]] && [[ "$content" == "Hello World!"* ]]; then
  echo "${GREEN_TEXT}${BOLD_TEXT}Success! Received 'Hello World!' with API key.${RESET_FORMAT}"
else
  echo "${RED_TEXT}${BOLD_TEXT}Error: Did not receive expected 'Hello World!' or 200 status with API key.${RESET_FORMAT}"
  # Add a retry mechanism for eventual consistency
  echo "${YELLOW_TEXT}Gateway might still be updating. Retrying in 30 seconds...${RESET_FORMAT}"
  sleep 30
  curl_output=$(curl -sL -w "\n%{http_code}" "${GATEWAY_URL}/hello?key=${API_KEY}")
  http_code=$(echo "$curl_output" | tail -n1)
  content=$(echo "$curl_output" | sed '$d')
  echo "Retry Response Content: $content"
  echo "Retry HTTP Status Code: $http_code"
  if [[ "$http_code" == "200" ]] && [[ "$content" == "Hello World!"* ]]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Success on retry! Received 'Hello World!' with API key.${RESET_FORMAT}"
  else
    echo "${RED_TEXT}${BOLD_TEXT}Error: Still incorrect response after retry.${RESET_FORMAT}"
  fi
fi
echo

# Completion message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}==================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}          LAB COMPLETED!          ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}==================================${RESET_FORMAT}"

# Subscription message
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
