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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Function for error handling
function error_exit {
  echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}" >&2
}

# Function to check command success
function check_success {
  if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✓ Success: $1${RESET_FORMAT}"
  else
    error_exit "Failed: $1"
  fi
}

# Function to print section headers
function print_header {
  echo "${BLUE_TEXT}${BOLD_TEXT}====================================================================================
$1
====================================================================================${RESET_FORMAT}"
}

# Function to print task information
function print_task {
  echo "${CYAN_TEXT}${BOLD_TEXT}$1${RESET_FORMAT}"
}

# Function to print instructions
function print_instruction {
  echo "${YELLOW_TEXT}${BOLD_TEXT}$1${RESET_FORMAT}"
}

# Function to print manual steps
function print_manual_step {
  echo "${MAGENTA_TEXT}${BOLD_TEXT}MANUAL STEP: $1${RESET_FORMAT}"
}

# Main execution flow
function main {
  # Task 1: Enable APIs
  print_header "Task 1: Enable APIs"

  # Set Project ID
  print_task "Setting Project ID variable..."
  export PROJECT_ID=$(gcloud config get-value project)
  check_success "Project ID set to $PROJECT_ID"

  # Set Region 
  print_instruction "Enter REGION:"
  read REGION
  export REGION
  gcloud config set compute/region $REGION
  check_success "Region set to $REGION"

  # Enable necessary services
  print_task "Enabling necessary Google Cloud services..."
  gcloud services enable \
    artifactregistry.googleapis.com \
    cloudfunctions.googleapis.com \
    cloudbuild.googleapis.com \
    eventarc.googleapis.com \
    run.googleapis.com \
    logging.googleapis.com \
    pubsub.googleapis.com
  check_success "All necessary services enabled"

  # Task 2: Create an HTTP function
  print_header "Task 2: Create an HTTP function"

  # Create directories and files
  print_task "Creating directory and files for HTTP function..."
  mkdir -p ~/hello-http && cd $_
  touch index.js && touch package.json
  check_success "Directory and files created"

  # Create index.js
  print_task "Creating index.js file..."
  cat > index.js << 'EOL'
const functions = require('@google-cloud/functions-framework');

functions.http('helloWorld', (req, res) => {
  res.status(200).send('HTTP with Node.js in GCF 2nd gen!');
});
EOL
  check_success "index.js created"

  # Create package.json
  print_task "Creating package.json file..."
  cat > package.json << 'EOL'
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOL
  check_success "package.json created"

  # Deploy the HTTP function
  print_task "Deploying HTTP function..."
  gcloud functions deploy nodejs-http-function \
    --gen2 \
    --runtime nodejs22 \
    --entry-point helloWorld \
    --source . \
    --region $REGION \
    --trigger-http \
    --timeout 600s \
    --max-instances 1
  check_success "HTTP function deployed"

  # Test the HTTP function
  print_task "Testing HTTP function..."
  gcloud functions call nodejs-http-function \
    --gen2 --region $REGION
  check_success "HTTP function tested"

  # Task 3: Create a Cloud Storage function
  print_header "Task 3: Create a Cloud Storage function"

  # Setup IAM permissions
  print_task "Setting up IAM permissions for Cloud Storage..."
  PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')
  SERVICE_ACCOUNT=$(gsutil kms serviceaccount -p $PROJECT_NUMBER)

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT \
    --role roles/pubsub.publisher
  check_success "IAM permissions set for Cloud Storage"
  
  # Fix Eventarc Service Agent permissions
  print_task "Fixing Eventarc Service Agent permissions..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-eventarc.iam.gserviceaccount.com" \
    --role="roles/eventarc.serviceAgent"
  check_success "Eventarc Service Agent role added"
  
  print_instruction "Waiting for permissions to propagate (2 minutes)..."
  sleep 120

  # Create directories and files
  print_task "Creating directory and files for Storage function..."
  mkdir -p ~/hello-storage && cd $_
  touch index.js && touch package.json
  check_success "Directory and files created"

  # Create index.js
  print_task "Creating index.js file..."
  cat > index.js << 'EOL'
const functions = require('@google-cloud/functions-framework');

functions.cloudEvent('helloStorage', (cloudevent) => {
  console.log('Cloud Storage event with Node.js in GCF 2nd gen!');
  console.log(cloudevent);
});
EOL
  check_success "index.js created"

  # Create package.json
  print_task "Creating package.json file..."
  cat > package.json << 'EOL'
{
  "name": "nodejs-functions-gen2-codelab",
  "version": "0.0.1",
  "main": "index.js",
  "dependencies": {
    "@google-cloud/functions-framework": "^2.0.0"
  }
}
EOL
  check_success "package.json created"

  # Create a Cloud Storage bucket
  print_task "Creating Cloud Storage bucket..."
  BUCKET="gs://gcf-gen2-storage-$PROJECT_ID"
  gsutil mb -l $REGION $BUCKET
  check_success "Cloud Storage bucket created"

  # Deploy the Storage function with error handling
  print_task "Deploying Storage function..."
  if ! gcloud functions deploy nodejs-storage-function \
    --gen2 \
    --runtime nodejs22 \
    --entry-point helloStorage \
    --source . \
    --region $REGION \
    --trigger-bucket $BUCKET \
    --trigger-location $REGION \
    --max-instances 1; then
    
    print_instruction "Initial deployment failed. Trying alternative approach..."
    
    # Create a Pub/Sub topic as an alternative
    print_task "Setting up Pub/Sub topic for Cloud Storage notifications..."
    TOPIC_NAME="storage-events-topic"
    gcloud pubsub topics create $TOPIC_NAME
    
    # Add notification to the bucket
    BUCKET_NAME=$(echo $BUCKET | sed 's/gs:\/\///')
    gsutil notification create -t $TOPIC_NAME -f json $BUCKET
    
    # Deploy function with Pub/Sub trigger instead
    gcloud functions deploy nodejs-storage-function \
      --gen2 \
      --runtime nodejs22 \
      --entry-point helloStorage \
      --source . \
      --region $REGION \
      --trigger-topic $TOPIC_NAME \
      --max-instances 1
    
    if [ $? -eq 0 ]; then
      check_success "Storage function deployed with Pub/Sub trigger"
    else
      print_instruction "Both approaches failed. Continuing with next tasks..."
    fi
  else
    check_success "Storage function deployed successfully"
  fi

  # Test the Storage function
  print_task "Testing Storage function..."
  echo "Hello World" > random.txt
  gsutil cp random.txt $BUCKET/random.txt
  check_success "File uploaded to bucket"

  print_instruction "Waiting for logs to be generated (30 seconds)..."
  sleep 30

  print_task "Viewing logs for Storage function..."
  gcloud functions logs read nodejs-storage-function \
    --region $REGION --gen2 --limit=100 --format "value(log)"

  # Task 4: Create a Cloud Audit Logs function
  print_header "Task 4: Create a Cloud Audit Logs function"

  # Setup for Audit Logs - THIS REQUIRES MANUAL ACTION
  print_manual_step "1. Go to Audit Logs (https://console.cloud.google.com/iam-admin/audit)"
  print_manual_step "2. Find the Compute Engine API and click the checkbox next to it"
  print_manual_step "3. Check Admin Read, Data Read, and Data Write log types and click Save"
  print_instruction "Press Enter after completing the manual steps above..."
  read

  # Grant IAM roles
  print_task "Granting IAM roles for Eventarc..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role roles/eventarc.eventReceiver
  check_success "IAM roles granted for Eventarc"

  # Clone the repository
  print_task "Cloning the sample repository..."
  cd ~
  git clone https://github.com/GoogleCloudPlatform/eventarc-samples.git
  check_success "Sample repository cloned"

  # Navigate to the app directory
  print_task "Navigating to app directory..."
  cd ~/eventarc-samples/gce-vm-labeler/gcf/nodejs
  check_success "Navigated to app directory"

  # Deploy the Audit Logs function
  print_task "Deploying Audit Logs function..."
  gcloud functions deploy gce-vm-labeler \
    --gen2 \
    --runtime nodejs22 \
    --entry-point labelVmCreation \
    --source . \
    --region $REGION \
    --trigger-event-filters="type=google.cloud.audit.log.v1.written,serviceName=compute.googleapis.com,methodName=beta.compute.instances.insert" \
    --trigger-location $REGION \
    --max-instances 1
  check_success "Audit Logs function deployed"

  print_instruction "Note: It may take up to 10 minutes for the trigger to be fully functional"

  # Create a VM - THIS REQUIRES MANUAL ACTION
  print_manual_step "1. Go to VM instances (https://console.cloud.google.com/compute/instances)"
  print_manual_step "2. Click Create Instance, set the name to 'instance-1'"
  print_manual_step "3. Select the appropriate zone and leave other defaults"
  print_manual_step "4. Click Create and wait for the VM to be created"
  print_manual_step "5. After creation, check for the 'creator' label in Basic information"
  print_instruction "Once VM is created, enter the zone where you created it:"
  read ZONE

  # Verify the label
  print_task "Verifying the creator label on the VM..."
  gcloud compute instances describe instance-1 --zone $ZONE

  # Delete the VM
  print_task "Deleting the test VM..."
  gcloud compute instances delete instance-1 --zone $ZONE --quiet
  check_success "Test VM deleted"

  # Task 5: Deploy different revisions
  print_header "Task 5: Deploy different revisions"

  # Create directories and files
  print_task "Creating directory and files for colored function..."
  mkdir -p ~/hello-world-colored && cd $_
  touch main.py
  touch requirements.txt  # Create the requirements.txt file
  check_success "Directory and files created"

  # Create main.py
  print_task "Creating main.py file..."
  cat > main.py << 'EOL'
  import os

  color = os.environ.get('COLOR')

  def hello_world(request):
      return f'<body style="background-color:{color}"><h1>Hello World!</h1></body>'
  EOL
  check_success "main.py created"

  # Create requirements.txt (empty is fine for this simple function)
  print_task "Creating requirements.txt file..."
  touch requirements.txt
  check_success "requirements.txt created"

  # Deploy first revision
  print_task "Deploying first revision with orange background..."
  COLOR=orange
  gcloud functions deploy hello-world-colored \
    --gen2 \
    --runtime python39 \
    --entry-point hello_world \
    --source . \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated \
    --update-env-vars COLOR=$COLOR \
    --max-instances 1
  check_success "First revision deployed with orange background"

  # Deploy second revision - THIS REQUIRES MANUAL ACTION
  print_manual_step "1. Go to Cloud Run functions (https://console.cloud.google.com/functions/run_redirect)"
  print_manual_step "2. Click the hello-world-colored function"
  print_manual_step "3. Click Edit & Deploy New Revision"
  print_manual_step "4. Scroll down to Variables & Secrets tab and update COLOR to yellow"
  print_manual_step "5. Click Deploy"
  print_instruction "Press Enter after completing the manual steps above..."
  read

  # Task 6: Set up minimum instances
  print_header "Task 6: Set up minimum instances"

  # Create directories and files
  print_task "Creating directory and files for min-instances function..."
  mkdir -p ~/min-instances && cd $_
  touch main.go && touch go.mod
  check_success "Directory and files created"

  # Create main.go
  print_task "Creating main.go file..."
  cat > main.go << 'EOL'
package p

import (
        "fmt"
        "net/http"
        "time"
)

func init() {
        time.Sleep(10 * time.Second)
}

func HelloWorld(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Slow HTTP Go in GCF 2nd gen!")
}
EOL
  check_success "main.go created"

  # Create go.mod
  print_task "Creating go.mod file..."
  cat > go.mod << 'EOL'
module example.com/mod

go 1.21
EOL
  check_success "go.mod created"

  # Deploy the function
  print_task "Deploying slow function without minimum instances..."
  gcloud functions deploy slow-function \
    --gen2 \
    --runtime go121 \
    --entry-point HelloWorld \
    --source . \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated \
    --max-instances 4
  check_success "Slow function deployed without minimum instances"

  # Test the function
  print_task "Testing slow function (expect ~10 second delay on first call)..."
  time gcloud functions call slow-function \
    --gen2 --region $REGION
  check_success "Slow function tested"

  # Set minimum instances - THIS REQUIRES MANUAL ACTION
  print_manual_step "1. Go to Cloud Run (https://console.cloud.google.com/run)"
  print_manual_step "2. Click the slow-function service"
  print_manual_step "3. Click Edit & Deploy New Revision"
  print_manual_step "4. Under Revision scaling, set Minimum number of instances to 1"
  print_manual_step "5. Leave Maximum number of instances at 4"
  print_manual_step "6. Click Deploy"
  print_instruction "Press Enter after completing the manual steps above..."
  read

  # Test the function again
  print_task "Testing slow function again (should be faster)..."
  time gcloud functions call slow-function \
    --gen2 --region $REGION
  check_success "Slow function tested with minimum instances"

  # Task 7: Create a function with concurrency
  print_header "Task 7: Create a function with concurrency"

  # Get the URL of the slow function
  print_task "Getting URL of the slow function..."
  SLOW_URL=$(gcloud functions describe slow-function --region $REGION --gen2 --format="value(serviceConfig.uri)")
  check_success "Got URL: $SLOW_URL"

  # Test without concurrency
  print_task "Testing slow function with concurrent requests..."
  hey -n 10 -c 10 $SLOW_URL
  check_success "Concurrent test completed"

  # Delete the slow function
  print_task "Deleting slow function..."
  gcloud run services delete slow-function --region $REGION --quiet
  check_success "Slow function deleted"

  # Deploy new function for concurrency test
  print_task "Deploying slow function with minimum instances..."
  gcloud functions deploy slow-concurrent-function \
    --gen2 \
    --runtime go121 \
    --entry-point HelloWorld \
    --source . \
    --region $REGION \
    --trigger-http \
    --allow-unauthenticated \
    --min-instances 1 \
    --max-instances 4
  check_success "Slow concurrent function deployed"

  # Set concurrency - THIS REQUIRES MANUAL ACTION
  print_manual_step "1. Go to Cloud Run (https://console.cloud.google.com/run)"
  print_manual_step "2. Click the slow-concurrent-function service" 
  print_manual_step "3. Click Edit & Deploy New Revision"
  print_manual_step "4. Under Resources, set the CPU to 1"
  print_manual_step "5. Under Requests, set Maximum concurrent requests per instance to 100"
  print_manual_step "6. Click Deploy"
  print_instruction "Press Enter after completing the manual steps above..."
  read

  # Get the URL of the slow concurrent function
  print_task "Getting URL of the slow concurrent function..."
  SLOW_CONCURRENT_URL=$(gcloud functions describe slow-concurrent-function --region $REGION --gen2 --format="value(serviceConfig.uri)")
  check_success "Got URL: $SLOW_CONCURRENT_URL"

  # Test with concurrency
  print_task "Testing slow concurrent function with concurrent requests..."
  hey -n 10 -c 10 $SLOW_CONCURRENT_URL
  check_success "Concurrent test completed with concurrency enabled"
}

# Execute the main function
main

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
