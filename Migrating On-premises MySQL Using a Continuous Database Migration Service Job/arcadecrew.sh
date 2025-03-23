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
error_exit() {
    echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}" >&2
    echo "${YELLOW_TEXT}${BOLD_TEXT}Exiting script. Please resolve the error and try again.${RESET_FORMAT}" >&2
}

# Success function
success_message() {
    echo "${GREEN_TEXT}${BOLD_TEXT}SUCCESS: $1${RESET_FORMAT}"
}

# Info function
info_message() {
    echo "${CYAN_TEXT}${BOLD_TEXT}INFO: $1${RESET_FORMAT}"
}

# Manual step notification
manual_step() {
    echo "${MAGENTA_TEXT}${BOLD_TEXT}MANUAL STEP REQUIRED: $1${RESET_FORMAT}"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    error_exit "gcloud CLI is not installed. Please install it before running this script."
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    error_exit "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    error_exit "Project ID not set. Please run 'gcloud config set project YOUR_PROJECT_ID' first."
fi

# Get region
REGION=$(gcloud config get-value compute/region)
if [ -z "$REGION" ]; then
    info_message "Compute region not set. Please enter region manually..."
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter region: " REGION ${RESET_FORMAT}
    if [ -z "$REGION" ]; then
        error_exit "No region provided. Exiting."
    fi
    gcloud config set compute/region "$REGION"
fi

# Get zone
ZONE=$(gcloud config get-value compute/zone)
if [ -z "$ZONE" ]; then
    info_message "Compute zone not set. Please enter zone manually..."
    read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter zone: " ZONE ${RESET_FORMAT}
    if [ -z "$ZONE" ]; then
        error_exit "No zone provided. Exiting."
    fi
    gcloud config set compute/zone "$ZONE"
fi

# Define API names
DB_MIGRATION_API="datamigration.googleapis.com"
SERVICE_NETWORKING_API="servicenetworking.googleapis.com"

# Function to check if an API is enabled
check_api_status() {
  local api=$1
  # Check if API is enabled
  gcloud services list --enabled --filter="NAME:${api}" --format="value(NAME)"
}

# Function to enable API if it's not enabled
enable_api() {
  local api=$1
  # Enable API
  echo "${BLUE_TEXT}${BOLD_TEXT}Enabling API: $api${RESET_FORMAT}"
  gcloud services enable $api
}

# Check Database Migration API
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Database Migration API status...${RESET_FORMAT}"
DB_MIGRATION_STATUS=$(check_api_status $DB_MIGRATION_API)
if [ -z "$DB_MIGRATION_STATUS" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Database Migration API is not enabled. Enabling it now...${RESET_FORMAT}"
  enable_api $DB_MIGRATION_API
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Database Migration API is already enabled.${RESET_FORMAT}"
fi

# Check Service Networking API
echo "${YELLOW_TEXT}${BOLD_TEXT}Checking Service Networking API status...${RESET_FORMAT}"
SERVICE_NETWORKING_STATUS=$(check_api_status $SERVICE_NETWORKING_API)
if [ -z "$SERVICE_NETWORKING_STATUS" ]; then
  echo "${RED_TEXT}${BOLD_TEXT}Service Networking API is not enabled. Enabling it now...${RESET_FORMAT}"
  enable_api $SERVICE_NETWORKING_API
else
  echo "${GREEN_TEXT}${BOLD_TEXT}Service Networking API is already enabled.${RESET_FORMAT}"
fi

echo "${YELLOW_TEXT}${BOLD_TEXT}API check and enable process completed.${RESET_FORMAT}"

# Task 1: Get the connectivity information for the MySQL source instance
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 1: Get MySQL source instance IP${RESET_FORMAT}"
echo ""

# Get the internal IP of the MySQL VM
info_message "Retrieving internal IP of the dms-mysql-training-vm-v2 VM..."

MYSQL_VM_IP=$(gcloud compute instances describe dms-mysql-training-vm-v2 --format="get(networkInterfaces[0].networkIP)")

if [ -z "$MYSQL_VM_IP" ]; then
    echo "${RED_TEXT}${BOLD_TEXT}Could not automatically retrieve IP. Please enter the IP manually:${RESET_FORMAT}"
    read MYSQL_VM_IP
    if [ -z "$MYSQL_VM_IP" ]; then
        error_exit "No IP address provided. Exiting..."
    fi
fi

success_message "MySQL source VM internal IP: ${MYSQL_VM_IP}"
echo ""

# Task 2: Create a new connection profile for the MySQL source instance
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 2: Create connection profile for MySQL source${RESET_FORMAT}"
echo ""

info_message "Creating connection profile for the MySQL source instance..."

# Create connection profile
gcloud database-migration connection-profiles create mysql-vm \
    --source-type=mysql \
    --mysql-hostname=$MYSQL_VM_IP \
    --mysql-port=3306 \
    --mysql-username=admin \
    --mysql-password=changeme \
    --region=$REGION \
    --display-name="mysql-vm" \
    --no-ssl || error_exit "Failed to create connection profile."

success_message "Connection profile 'mysql-vm' created successfully."
echo ""

# Task 3: Create and start a continuous migration job
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 3: Create and start a continuous migration job${RESET_FORMAT}"
echo ""

info_message "Creating a new Cloud SQL for MySQL instance as destination..."

# Create the Cloud SQL instance
gcloud sql instances create mysql-cloudsql \
    --database-version=MYSQL_5_7 \
    --region=$REGION \
    --zone=$ZONE \
    --tier=db-g1-small \
    --storage-size=10GB \
    --root-password=supersecret! \
    --availability-type=zonal \
    --network=default \
    --allocated-ip-range-name=google-managed-services-default \
    --async || error_exit "Failed to create Cloud SQL instance."

info_message "Waiting for Cloud SQL instance to be ready... This may take several minutes."
gcloud sql instances wait --for-any-status mysql-cloudsql || error_exit "Error waiting for Cloud SQL instance."

# Check if the instance is ready
INSTANCE_STATUS=$(gcloud sql instances describe mysql-cloudsql --format="value(state)")
if [ "$INSTANCE_STATUS" != "RUNNABLE" ]; then
    manual_step "The Cloud SQL instance is not yet ready. Current status: $INSTANCE_STATUS. Please wait until it's RUNNABLE before proceeding."
    manual_step "Check status with: gcloud sql instances describe mysql-cloudsql --format=\"value(state)\""
    manual_step "Press Enter when the instance is ready to continue..."
    read
fi

info_message "Creating migration job..."

# Create migration job
gcloud database-migration migration-jobs create vm-to-cloudsql \
    --source-connection-profile=mysql-vm \
    --destination-connection-profile-type=CLOUDSQL \
    --destination-connection-profile-cloudsql-instance-name=mysql-cloudsql \
    --migration-job-type=CONTINUOUS \
    --peer-vpc=default \
    --region=$REGION \
    --async || error_exit "Failed to create migration job."

info_message "Waiting for migration job to be created... This may take several minutes."

# Check if migration job is created
for i in {1..30}; do
    JOB_STATUS=$(gcloud database-migration migration-jobs describe vm-to-cloudsql --region=$REGION --format="value(state)" 2>/dev/null)
    if [ -n "$JOB_STATUS" ]; then
        break
    fi
    echo -n "."
    sleep 10
done
echo ""

if [ -z "$JOB_STATUS" ]; then
    manual_step "Could not automatically verify the migration job status. Please check the Google Cloud Console."
    manual_step "Go to Database Migration > Migration jobs and check if 'vm-to-cloudsql' has been created."
    manual_step "Press Enter when ready to continue..."
    read
else
    success_message "Migration job created with status: $JOB_STATUS"
fi

info_message "Starting migration job..."

# Start migration job
gcloud database-migration migration-jobs start vm-to-cloudsql --region=$REGION || error_exit "Failed to start migration job."

success_message "Migration job started successfully."
echo ""

# Task 4: Review the status of the continuous migration job
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 4: Review migration job status${RESET_FORMAT}"
echo ""

info_message "Checking migration job status..."

# Check migration job status
JOB_STATUS=$(gcloud database-migration migration-jobs describe vm-to-cloudsql --region=$REGION --format="value(state)" 2>/dev/null)

if [ -z "$JOB_STATUS" ]; then
    manual_step "Could not automatically retrieve migration job status. Please check the Google Cloud Console."
    manual_step "Go to Database Migration > Migration jobs and click on 'vm-to-cloudsql' to see details."
else
    info_message "Current migration job status: $JOB_STATUS"
    
    if [ "$JOB_STATUS" != "RUNNING" ]; then
        manual_step "The migration job is not yet in RUNNING state. Current status: $JOB_STATUS."
        manual_step "Please wait until the status changes to RUNNING before proceeding."
        manual_step "You can check status in the Google Cloud Console or with:"
        manual_step "gcloud database-migration migration-jobs describe vm-to-cloudsql --region=$REGION --format=\"value(state)\""
        manual_step "Press Enter when the job is running to continue..."
        read
    else
        success_message "Migration job is in RUNNING state."
    fi
fi
echo ""

# Task 5: Confirm the data in Cloud SQL for MySQL
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 5: Confirm data in Cloud SQL${RESET_FORMAT}"
echo ""

info_message "The following steps require manual verification of the data in Cloud SQL."
manual_step "1. Open the Google Cloud Console and navigate to Databases > SQL."
manual_step "2. Click on the instance 'mysql-cloudsql'."
manual_step "3. Click on 'Databases' in the left menu and verify that 'customers_data' and 'sales_data' databases exist."
manual_step "4. Click on 'Open Cloud Shell' and run the following commands:"
manual_step "   gcloud sql connect mysql-cloudsql --user=root --quiet"
manual_step "   When prompted for password, enter: supersecret!"
manual_step "   Then run these MySQL commands:"
manual_step "   use customers_data;"
manual_step "   select count(*) from customers;"  
manual_step "   select * from customers order by lastName limit 10;"
manual_step "   exit"
manual_step "Press Enter once you've verified the data to continue..."
read
echo ""

# Task 6: Test continuous migration
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 6: Test continuous migration${RESET_FORMAT}"
echo ""

info_message "This task requires adding data to the source MySQL instance and verifying it appears in Cloud SQL."
manual_step "1. In the Google Cloud Console, navigate to Compute Engine > VM instances."
manual_step "2. Connect to 'dms-mysql-training-vm-v2' via SSH."
manual_step "3. Run the following commands to add data to the source MySQL:"
manual_step "   mysql -u admin -p"
manual_step "   When prompted for password, enter: changeme"
manual_step "   use customers_data;"
manual_step "   INSERT INTO customers (customerKey, addressKey, title, firstName, lastName, birthdate, gender, maritalStatus, email, creationDate)"
manual_step "   VALUES ('9365552000000-999', '9999999', 'Ms', 'Magna', 'Ablorem', '1953-07-28 00:00:00', 'FEMALE', 'MARRIED', 'magna.lorem@gmail.com', CURRENT_TIMESTAMP),"
manual_step "   ('9965552000000-9999', '99999999', 'Mr', 'Arcu', 'Abrisus', '1959-07-28 00:00:00', 'MALE', 'MARRIED', 'arcu.risus@gmail.com', CURRENT_TIMESTAMP);"
manual_step "   select count(*) from customers;"
manual_step "   select * from customers order by lastName limit 10;"
manual_step "   exit"
manual_step "   exit"
manual_step ""
manual_step "4. Then verify the data appears in Cloud SQL by connecting to it and running the same queries:"
manual_step "   Open Cloud Shell for mysql-cloudsql and run:"
manual_step "   use customers_data;"
manual_step "   select count(*) from customers;"
manual_step "   select * from customers order by lastName limit 10;"
manual_step "   exit"
manual_step "Press Enter once you've verified the data appears in Cloud SQL to continue..."
read
echo ""

# Task 7: Promote Cloud SQL
echo "${BLUE_TEXT}${BOLD_TEXT}TASK 7: Promote Cloud SQL to standalone instance${RESET_FORMAT}"
echo ""

info_message "Promoting Cloud SQL instance to be a standalone instance..."

# Promote migration job
gcloud database-migration migration-jobs promote vm-to-cloudsql --region=$REGION || error_exit "Failed to promote migration job."

# Check promotion status
for i in {1..10}; do
    JOB_STATUS=$(gcloud database-migration migration-jobs describe vm-to-cloudsql --region=$REGION --format="value(state)" 2>/dev/null)
    if [ "$JOB_STATUS" == "COMPLETED" ]; then
        break
    fi
    info_message "Waiting for promotion to complete. Current status: $JOB_STATUS"
    sleep 10
done

if [ "$JOB_STATUS" == "COMPLETED" ]; then
    success_message "Cloud SQL instance has been successfully promoted to a standalone instance!"
else
    manual_step "Promotion is still in progress. Current status: $JOB_STATUS"
    manual_step "You can check the final status in the Google Cloud Console."
fi

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo