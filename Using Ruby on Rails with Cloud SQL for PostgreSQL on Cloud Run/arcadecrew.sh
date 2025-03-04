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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION: ${RESET_FORMAT}" REGION

echo "${GREEN_TEXT}${BOLD_TEXT}You have selected region: ${REGION}${RESET_FORMAT}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Authenticating with Google Cloud...${RESET_FORMAT}"
gcloud auth list

echo "${MAGENTA_TEXT}${BOLD_TEXT}Cloning the repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/ruby-docs-samples.git

echo "${MAGENTA_TEXT}${BOLD_TEXT}Navigating to the Rails directory...${RESET_FORMAT}"
cd ruby-docs-samples/run/rails

echo "${MAGENTA_TEXT}${BOLD_TEXT}Installing dependencies with bundle...${RESET_FORMAT}"
bundle install

INSTANCE_NAME=postgres-instance
DATABASE_NAME=mydatabase

echo "${BLUE_TEXT}${BOLD_TEXT}Enabling required services (secretmanager.googleapis.com and run.googleapis.com)...${RESET_FORMAT}"
gcloud services enable secretmanager.googleapis.com
gcloud services enable run.googleapis.com

echo "${BLUE_TEXT}${BOLD_TEXT}Creating Cloud SQL instance...${RESET_FORMAT}"
gcloud sql instances create $INSTANCE_NAME \
  --database-version POSTGRES_12 \
  --tier db-g1-small \
  --region $REGION

echo "${BLUE_TEXT}${BOLD_TEXT}Creating database within the Cloud SQL instance...${RESET_FORMAT}"
gcloud sql databases create $DATABASE_NAME \
  --instance $INSTANCE_NAME

echo "${BLUE_TEXT}${BOLD_TEXT}Generating a random password for the database user...${RESET_FORMAT}"
cat /dev/urandom | LC_ALL=C tr -dc '[:alpha:]'| fold -w 50 | head -n1 > dbpassword

echo "${BLUE_TEXT}${BOLD_TEXT}Creating a database user...${RESET_FORMAT}"
gcloud sql users create qwiklabs_user \
  --instance=$INSTANCE_NAME --password=$(cat dbpassword)

BUCKET_NAME=$DEVSHELL_PROJECT_ID-ruby
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb -l $REGION gs://$BUCKET_NAME

echo "${BLUE_TEXT}${BOLD_TEXT}Setting bucket permissions to public read...${RESET_FORMAT}"
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME

PASSWORD="$(cat ~/ruby-docs-samples/run/rails/dbpassword)"

# Make sure PASSWORD is set
if [ -z "$PASSWORD" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}PASSWORD environment variable is not set.${RESET_FORMAT}"
  exit 1
fi

echo "${MAGENTA_TEXT}${BOLD_TEXT}Decrypting and modifying Rails credentials...${RESET_FORMAT}"
# Decrypt, add the line with the actual password, and re-encrypt
EDITOR="sed -i -e '\$a\\gcp:\n  db_password: $PASSWORD'" bin/rails credentials:edit

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a secret in Secret Manager...${RESET_FORMAT}"
gcloud secrets create rails_secret --data-file config/master.key

echo "${MAGENTA_TEXT}${BOLD_TEXT}Describing the newly created secret...${RESET_FORMAT}"
gcloud secrets describe rails_secret

echo "${MAGENTA_TEXT}${BOLD_TEXT}Accessing the latest version of the secret...${RESET_FORMAT}"
gcloud secrets versions access latest --secret rails_secret

PROJECT_NUMBER=$(gcloud projects describe $DEVSHELL_PROJECT_ID --format='value(projectNumber)')

echo "${MAGENTA_TEXT}${BOLD_TEXT}Granting Secret Manager access to compute engine service account...${RESET_FORMAT}"
gcloud secrets add-iam-policy-binding rails_secret \
  --member serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role roles/secretmanager.secretAccessor

echo "${MAGENTA_TEXT}${BOLD_TEXT}Granting Secret Manager access to cloud build service account...${RESET_FORMAT}"
gcloud secrets add-iam-policy-binding rails_secret \
  --member serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role roles/secretmanager.secretAccessor

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the .env file with environment variables...${RESET_FORMAT}"
cat << EOF > .env
PRODUCTION_DB_NAME: $DATABASE_NAME
PRODUCTION_DB_USERNAME: qwiklabs_user
CLOUD_SQL_CONNECTION_NAME: $DEVSHELL_PROJECT_ID:$REGION:$INSTANCE_NAME
GOOGLE_PROJECT_ID: $DEVSHELL_PROJECT_ID
STORAGE_BUCKET_NAME: $BUCKET_NAME
EOF

echo "${MAGENTA_TEXT}${BOLD_TEXT}Granting Cloud SQL Client role to Cloud Build service account...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
    --role roles/cloudsql.client

echo "${MAGENTA_TEXT}${BOLD_TEXT}Updating the Dockerfile with the correct Ruby version...${RESET_FORMAT}"
RUBY_VERSION=$(ruby -v | cut -d ' ' -f2 | cut -c1-3)
sed -i "/FROM/c\FROM ruby:$RUBY_VERSION-buster" Dockerfile

APP_NAME=myrubyapp

echo "${YELLOW_TEXT}${BOLD_TEXT}Submitting the build to Cloud Build... This might take a few minutes.${RESET_FORMAT}"
gcloud builds submit --config cloudbuild.yaml \
    --substitutions _SERVICE_NAME=$APP_NAME,_INSTANCE_NAME=$INSTANCE_NAME,_REGION=$REGION,_SECRET_NAME=rails_secret --timeout=20m

echo "${YELLOW_TEXT}${BOLD_TEXT}Deploying the application to Cloud Run...${RESET_FORMAT}"
gcloud run deploy $APP_NAME \
    --platform managed \
    --region $REGION \
    --image gcr.io/$DEVSHELL_PROJECT_ID/$APP_NAME \
    --add-cloudsql-instances $DEVSHELL_PROJECT_ID:$REGION:$INSTANCE_NAME \
    --allow-unauthenticated \
    --max-instances=3 \
    --quiet
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
