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
section_header() {
    echo ""
    echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
    echo "${MAGENTA_TEXT}${BOLD_TEXT} $1 ${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
    echo ""
}

# Function to display task information
task_info() {
    echo "${CYAN_TEXT}${BOLD_TEXT}$1${RESET_FORMAT}"
}

# Function to display success messages
success_msg() {
    echo "${GREEN_TEXT}${BOLD_TEXT}✓ $1${RESET_FORMAT}"
}

# Function to display error messages and exit
error_msg() {
    echo "${RED_TEXT}${BOLD_TEXT}✗ ERROR: $1${RESET_FORMAT}"
}

# Function to display manual step instructions
manual_step() {
    echo "${YELLOW_TEXT}${BOLD_TEXT}⚠ MANUAL STEP: $1${RESET_FORMAT}"
}

# Function to run a command and check for errors
run_command() {
    echo "${CYAN_TEXT}$ $1${RESET_FORMAT}"
    eval $1
    if [ $? -ne 0 ]; then
        error_msg "Command failed: $1"
    fi
}

# Function to verify a condition and display appropriate message
verify_condition() {
    if eval $1; then
        success_msg "$2"
    else
        error_msg "$3"
    fi
}

# Initialize variables
section_header "Initializing Lab Environment"

# Set environment variables
CLOUD_SQL_INSTANCE="postgres-orders"
NEW_INSTANCE_NAME="postgres-orders-pitr"

task_info "Setting up environment variables"
echo "${GREEN_TEXT}CLOUD_SQL_INSTANCE=${BOLD_TEXT}$CLOUD_SQL_INSTANCE${RESET_FORMAT}"
echo "${GREEN_TEXT}NEW_INSTANCE_NAME=${BOLD_TEXT}$NEW_INSTANCE_NAME${RESET_FORMAT}"
echo ""

#########################
# Task 1: Enable backups on the Cloud SQL for PostgreSQL instance
#########################
section_header "Task 1: Enable backups on the Cloud SQL for PostgreSQL instance"

# Display instance details
task_info "Displaying Cloud SQL instance details"
run_command "gcloud sql instances describe \$CLOUD_SQL_INSTANCE"

# Get current time and calculate an appropriate backup time (1 hour earlier)
task_info "Getting current UTC time"
run_command "date +\"%R\""
CURRENT_HOUR=$(date -u +"%H")
BACKUP_HOUR=$((CURRENT_HOUR - 1))
if [ $BACKUP_HOUR -lt 0 ]; then
    BACKUP_HOUR=23
fi
BACKUP_TIME=$(printf "%02d:00" $BACKUP_HOUR)
echo "${YELLOW_TEXT}${BOLD_TEXT}Setting backup time to: ${BACKUP_TIME}${RESET_FORMAT}"

# Enable scheduled backups
task_info "Enabling scheduled backups"
run_command "gcloud sql instances patch \$CLOUD_SQL_INSTANCE --backup-start-time=$BACKUP_TIME"

# Verify backup configuration
task_info "Verifying backup configuration"
run_command "gcloud sql instances describe \$CLOUD_SQL_INSTANCE --format 'value(settings.backupConfiguration)'"

success_msg "Task 1 Complete: Backups enabled for Cloud SQL instance"

#########################
# Task 2: Enable and run point-in-time recovery
#########################
section_header "Task 2: Enable and run point-in-time recovery"

# Enable point-in-time recovery
task_info "Enabling point-in-time recovery"
run_command "gcloud sql instances patch \$CLOUD_SQL_INSTANCE --enable-point-in-time-recovery --retained-transaction-log-days=1"

# Get timestamp for point-in-time recovery
task_info "Getting current timestamp for point-in-time recovery reference"
TIMESTAMP=$(date --rfc-3339=seconds)
echo "${YELLOW_TEXT}${BOLD_TEXT}Current timestamp (save this for later): ${TIMESTAMP}${RESET_FORMAT}"

# Manual steps for modifying the database
echo ""
manual_step "Please perform the following steps manually:"
echo "${YELLOW_TEXT}1. In Cloud Console, navigate to Databases > SQL and click on 'postgres-orders'${RESET_FORMAT}"
echo "${YELLOW_TEXT}2. In the 'Connect to this instance' section, click 'Open Cloud Shell'${RESET_FORMAT}"
echo "${YELLOW_TEXT}3. Run the auto-populated command and enter password: ${BOLD_TEXT}supersecret!${RESET_FORMAT}"
echo "${YELLOW_TEXT}4. In psql, run: ${BOLD_TEXT}\\c orders${RESET_FORMAT}"
echo "${YELLOW_TEXT}5. Enter the password again: ${BOLD_TEXT}supersecret!${RESET_FORMAT}"
echo "${YELLOW_TEXT}6. Run: ${BOLD_TEXT}SELECT COUNT(*) FROM distribution_centers;${RESET_FORMAT}"
echo "${YELLOW_TEXT}   You should see 10 rows${RESET_FORMAT}"
echo "${YELLOW_TEXT}7. Wait a few moments to ensure changes occur after the timestamp${RESET_FORMAT}"
echo "${YELLOW_TEXT}8. Run: ${BOLD_TEXT}INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);${RESET_FORMAT}"
echo "${YELLOW_TEXT}9. Run: ${BOLD_TEXT}SELECT COUNT(*) FROM distribution_centers;${RESET_FORMAT}"
echo "${YELLOW_TEXT}   You should now see 11 rows${RESET_FORMAT}"
echo "${YELLOW_TEXT}10. Exit psql by typing: ${BOLD_TEXT}\\q${RESET_FORMAT}"
echo ""

# Ask user to confirm when manual steps are complete
read -p "${CYAN_TEXT}${BOLD_TEXT}Have you completed the manual steps? (y/n): ${RESET_FORMAT}" confirm
if [[ $confirm != [Yy]* ]]; then
    error_msg "Manual steps must be completed before continuing"
fi

# Create point-in-time recovery clone
task_info "Creating point-in-time recovery clone"
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter the timestamp you saved earlier (format: YYYY-MM-DD HH:MM:SS):${RESET_FORMAT}"
read user_timestamp

echo "${GREEN_TEXT}Creating clone using timestamp: ${BOLD_TEXT}$user_timestamp${RESET_FORMAT}"
run_command "gcloud sql instances clone \$CLOUD_SQL_INSTANCE \$NEW_INSTANCE_NAME --point-in-time '$user_timestamp'"

echo "${YELLOW_TEXT}${BOLD_TEXT}Note: Clone creation may take 10+ minutes. Continue with the next task while waiting.${RESET_FORMAT}"
success_msg "Task 2 Complete: Point-in-time recovery initiated"

#########################
# Task 3: Confirm database has been restored to the correct point-in-time
#########################
section_header "Task 3: Confirm database has been restored to the correct point-in-time"

# Manual steps for verification
manual_step "Please perform the following steps manually:"
echo "${YELLOW_TEXT}1. In Cloud Console, navigate to SQL instances and click on 'postgres-orders-pitr'${RESET_FORMAT}"
echo "${YELLOW_TEXT}   You may need to wait until the clone is fully created (wait for status: Running)${RESET_FORMAT}"
echo "${YELLOW_TEXT}2. In the 'Connect to this instance' section, click 'Open Cloud Shell'${RESET_FORMAT}"
echo "${YELLOW_TEXT}3. Run the auto-populated command and enter password: ${BOLD_TEXT}supersecret!${RESET_FORMAT}"
echo "${YELLOW_TEXT}4. In psql, run: ${BOLD_TEXT}\\c orders${RESET_FORMAT}"
echo "${YELLOW_TEXT}5. Enter the password again: ${BOLD_TEXT}supersecret!${RESET_FORMAT}"
echo "${YELLOW_TEXT}6. Run: ${BOLD_TEXT}SELECT COUNT(*) FROM distribution_centers;${RESET_FORMAT}"
echo "${YELLOW_TEXT}   You should see 10 rows, confirming the point-in-time recovery worked correctly${RESET_FORMAT}"
echo "${YELLOW_TEXT}7. Exit psql by typing: ${BOLD_TEXT}\\q${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
