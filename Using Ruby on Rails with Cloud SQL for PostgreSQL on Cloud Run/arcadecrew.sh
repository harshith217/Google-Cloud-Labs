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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Function to display section headers
section() {
  echo ""
  echo "${BLUE_TEXT}${BOLD_TEXT}===== $1 =====${RESET_FORMAT}"
  echo ""
}

# Function to display steps
step() {
  echo "${CYAN_TEXT}${BOLD_TEXT}>> $1${RESET_FORMAT}"
}

# Function to display success messages
success() {
  echo "${GREEN_TEXT}${BOLD_TEXT}✓ $1${RESET_FORMAT}"
}

# Function to display error messages and exit
error() {
  echo "${RED_TEXT}${BOLD_TEXT}✗ ERROR: $1${RESET_FORMAT}"
  exit 1
}

# Function to display warnings
warning() {
  echo "${YELLOW_TEXT}${BOLD_TEXT}! WARNING: $1${RESET_FORMAT}"
}

# Function to display manual steps
manual() {
  echo "${MAGENTA_TEXT}${BOLD_TEXT}⟹ MANUAL STEP: $1${RESET_FORMAT}"
}

# Function to check command execution status
check_status() {
  if [ $? -eq 0 ]; then
    success "$1"
  else
    error "$2"
  fi
}

# Get user confirmation to proceed
confirm_proceed() {
  echo "${YELLOW_TEXT}${BOLD_TEXT}? $1 (y/n)${RESET_FORMAT}"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled by user."
    exit 0
  fi
}

# Check if gcloud is installed and authenticated
check_gcloud() {
  step "Checking if gcloud CLI is installed and authenticated..."
  if ! command -v gcloud &> /dev/null; then
    error "gcloud CLI is not installed. Please install it first."
  fi
  
  if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    error "Not authenticated with gcloud. Please run 'gcloud auth login' first."
  fi
  
  success "gcloud CLI is installed and authenticated"
}

# Set region based on user input or default
set_region() {
  # Ask for region or use default
  echo "${CYAN_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
  read -r user_region
  REGION=${user_region:-"us-central1"}
  
  echo "${GREEN_TEXT}Using region: $REGION${RESET_FORMAT}"
}

########################
# BEGIN SCRIPT EXECUTION
########################

# Check prerequisites
check_gcloud
set_region

# Set environment variables
INSTANCE_NAME="postgres-instance"
DATABASE_NAME="mydatabase"
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="${PROJECT_ID}-ruby"
APP_NAME="myrubyapp"

section "TASK 1: PREPARING YOUR ENVIRONMENT"

# Clone the repository
step "Cloning the Rails app repository..."
if [ ! -d "ruby-docs-samples" ]; then
  git clone https://github.com/GoogleCloudPlatform/ruby-docs-samples.git
  check_status "Repository cloned successfully" "Failed to clone repository"
else
  warning "Repository already exists, skipping clone"
fi

# Install dependencies
step "Installing required dependencies..."
cd ruby-docs-samples/run/rails || error "Failed to navigate to rails directory"
bundle install
check_status "Dependencies installed successfully" "Failed to install dependencies"

section "TASK 2: PREPARING THE BACKING SERVICES"

# Set up Cloud SQL for PostgreSQL instance
step "Creating PostgreSQL instance (this may take a few minutes)..."
gcloud sql instances create $INSTANCE_NAME \
  --database-version POSTGRES_12 \
  --tier db-g1-small \
  --region $REGION
check_status "PostgreSQL instance created successfully" "Failed to create PostgreSQL instance"

# Create the database
step "Creating database '$DATABASE_NAME'..."
gcloud sql databases create $DATABASE_NAME \
  --instance $INSTANCE_NAME
check_status "Database created successfully" "Failed to create database"

# Generate random password and create user
step "Generating random password for database user..."
cat /dev/urandom | LC_ALL=C tr -dc '[:alpha:]' | fold -w 50 | head -n1 > dbpassword
check_status "Password generated successfully" "Failed to generate password"

step "Creating database user 'qwiklabs_user'..."
gcloud sql users create qwiklabs_user \
  --instance=$INSTANCE_NAME --password=$(cat dbpassword)
check_status "Database user created successfully" "Failed to create database user"

# Set up Cloud Storage bucket
step "Creating Cloud Storage bucket '$BUCKET_NAME'..."
gsutil mb -l $REGION gs://$BUCKET_NAME
check_status "Storage bucket created successfully" "Failed to create storage bucket"

step "Setting bucket permissions for public image viewing..."
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME
check_status "Bucket permissions set successfully" "Failed to set bucket permissions"

section "TASK 3: STORE SECRET VALUES IN SECRET MANAGER"

# Create encrypted credentials file
step "Generating Rails credentials file..."
warning "The following step requires manual intervention to edit the credentials file"
manual "When the editor opens, add this at the end of the file:"
echo "${YELLOW_TEXT}gcp:
  db_password: $(cat dbpassword)${RESET_FORMAT}"
manual "Then save and exit the editor (Ctrl+X, then Y to confirm)"

confirm_proceed "Ready to open the editor and create credentials file?"
EDITOR="nano" bin/rails credentials:edit

# Store key in Secret Manager
step "Creating Secret Manager secret 'rails_secret'..."
gcloud services enable secretmanager.googleapis.com
check_status "Secret Manager API enabled" "Failed to enable Secret Manager API"

gcloud secrets create rails_secret --data-file config/master.key
check_status "Secret created successfully" "Failed to create secret"

step "Verifying secret creation..."
gcloud secrets describe rails_secret > /dev/null
check_status "Secret verified" "Failed to verify secret"

# Get project number for IAM permissions
step "Getting project number for IAM permissions..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
check_status "Project number retrieved" "Failed to retrieve project number"

# Grant access to secret
step "Granting access to secret for Cloud Run service account..."
gcloud secrets add-iam-policy-binding rails_secret \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/secretmanager.secretAccessor
check_status "Access granted to Cloud Run service account" "Failed to grant access"

step "Granting access to secret for Cloud Build service account..."
gcloud secrets add-iam-policy-binding rails_secret \
  --member serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role roles/secretmanager.secretAccessor
check_status "Access granted to Cloud Build service account" "Failed to grant access"

# Configure Rails app to connect to database and storage
step "Configuring Rails app environment variables..."
cat << EOF > .env
PRODUCTION_DB_NAME: $DATABASE_NAME
PRODUCTION_DB_USERNAME: qwiklabs_user
CLOUD_SQL_CONNECTION_NAME: $PROJECT_ID:$REGION:$INSTANCE_NAME
GOOGLE_PROJECT_ID: $PROJECT_ID
STORAGE_BUCKET_NAME: $BUCKET_NAME
EOF
check_status "Environment variables configured" "Failed to configure environment variables"

# Grant Cloud Build access to Cloud SQL
step "Granting Cloud Build access to Cloud SQL..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
    --role roles/cloudsql.client
check_status "Cloud SQL access granted to Cloud Build" "Failed to grant Cloud SQL access"

section "TASK 4: DEPLOYING THE APP TO CLOUD RUN"

# Update Ruby version in Dockerfile
step "Updating Ruby version in Dockerfile..."
RUBY_VERSION=$(ruby -v | cut -d ' ' -f2 | cut -c1-3)
sed -i "/FROM/c\FROM ruby:$RUBY_VERSION-buster" Dockerfile
check_status "Dockerfile updated successfully" "Failed to update Dockerfile"

# Create Artifact Registry repository
step "Creating Artifact Registry repository..."
gcloud services enable artifactregistry.googleapis.com
check_status "Artifact Registry API enabled" "Failed to enable Artifact Registry API"

gcloud artifacts repositories create cloud-run-source-deploy \
  --repository-format=docker \
  --location=$REGION
check_status "Artifact Repository created successfully" "Failed to create Artifact Repository"

# Enable Cloud Run Admin API
step "Enabling Cloud Run Admin API..."
gcloud services enable run.googleapis.com
check_status "Cloud Run Admin API enabled" "Failed to enable Cloud Run Admin API"

# Build and deploy using Cloud Build with automatic retry on timeout
step "Building and deploying application with Cloud Build (this may take several minutes)..."

# Initialize variables for retry mechanism
MAX_ATTEMPTS=10
ATTEMPT=1
TIMEOUT=1200  # Initial timeout in seconds (20 minutes)

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "${YELLOW_TEXT}${BOLD_TEXT}Cloud Build attempt $ATTEMPT with timeout ${TIMEOUT}s${RESET_FORMAT}"
  
  # Run the Cloud Build command
  gcloud builds submit --config cloudbuild.yaml \
    --substitutions _SERVICE_NAME=$APP_NAME,_INSTANCE_NAME=$INSTANCE_NAME,_REGION=$REGION,_SECRET_NAME=rails_secret \
    --timeout=${TIMEOUT}s
  
  BUILD_STATUS=$?
  
  # Check if build was successful
  if [ $BUILD_STATUS -eq 0 ]; then
    success "Cloud Build completed successfully on attempt $ATTEMPT"
    break
  else
    warning "Cloud Build failed on attempt $ATTEMPT with timeout ${TIMEOUT}s"
    
    # Increase timeout for next attempt
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
      # Increase timeout by 50%
      TIMEOUT=$(( TIMEOUT * 3 / 2 ))
      
      echo "${YELLOW_TEXT}${BOLD_TEXT}Increasing timeout to ${TIMEOUT}s and retrying...${RESET_FORMAT}"
      ATTEMPT=$((ATTEMPT+1))
    else
      error "Cloud Build failed after $MAX_ATTEMPTS attempts. Please try manually with increased timeout."
    fi
  fi
done

# Final check to ensure we don't continue if all attempts failed
if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
  error "Cloud Build failed after all retry attempts"
fi

# Deploy to Cloud Run
step "Deploying application to Cloud Run..."
gcloud run deploy $APP_NAME \
    --platform managed \
    --region $REGION \
    --image $REGION-docker.pkg.dev/$PROJECT_ID/cloud-run-source-deploy/$APP_NAME \
    --add-cloudsql-instances $PROJECT_ID:$REGION:$INSTANCE_NAME \
    --allow-unauthenticated \
    --max-instances=3
check_status "Cloud Run deployment completed successfully" "Failed to deploy to Cloud Run"

# Get the service URL
SERVICE_URL=$(gcloud run services describe $APP_NAME --region=$REGION --format='value(status.url)')

section "DEPLOYMENT COMPLETE"
echo "${GREEN_TEXT}${BOLD_TEXT}Your Rails application has been successfully deployed!"
echo "Service URL: ${SERVICE_URL}${RESET_FORMAT}"
echo ""
echo "${CYAN_TEXT}${BOLD_TEXT}Visit the URL to see your Cat Photo Album application"
echo "You can try uploading a photo to test the full functionality${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
