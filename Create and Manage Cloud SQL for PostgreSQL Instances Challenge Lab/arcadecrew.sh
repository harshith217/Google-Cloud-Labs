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

#!/bin/bash

# Color codes
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Error handling function
error_handling() {
  echo "${RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}"
  exit 1
}

# Success message function
success_message() {
  echo "${GREEN_TEXT}${BOLD_TEXT}SUCCESS: $1${RESET_FORMAT}"
}

# Task header function
task_header() {
  echo "${BLUE_TEXT}${BOLD_TEXT}TASK $1: $2${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
}

# Manual step function
manual_step() {
  echo "${YELLOW_TEXT}${BOLD_TEXT}MANUAL STEP: $1${RESET_FORMAT}"
}

# Command execution with error checking
execute_command() {
  echo "${MAGENTA_TEXT}${BOLD_TEXT}Executing: $1${RESET_FORMAT}"
  eval $1
  if [ $? -ne 0 ]; then
    error_handling "Command failed: $1"
  fi
}

# Initialize variables
get_variables() {
  echo "${CYAN_TEXT}${BOLD_TEXT}Initializing variables...${RESET_FORMAT}"
  
  # Get project ID
  PROJECT_ID=$(gcloud config get-value project)
  
  # Get region
  REGION=$(gcloud config get-value compute/region)
  if [ -z "$REGION" ]; then
    REGION=$(gcloud config get-value compute/zone | awk -F- '{print $1"-"$2}')
  fi
  
  # Get postgres-vm IP addresses
  POSTGRES_VM_ZONE=$(gcloud compute instances list --filter="name=postgres-vm" --format="value(zone)")
  POSTGRES_VM_INTERNAL_IP=$(gcloud compute instances describe postgres-vm --zone=${POSTGRES_VM_ZONE} --format="value(networkInterfaces[0].networkIP)")
  POSTGRES_VM_EXTERNAL_IP=$(gcloud compute instances describe postgres-vm --zone=${POSTGRES_VM_ZONE} --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
  
  # Set Cloud SQL instance ID
  CLOUDSQL_INSTANCE_ID="migrated-postgresql-instance"
  
  # Get Qwiklabs username
  QWIKLABS_USER=$(gcloud config get-value account | cut -d '@' -f 1)
  
  # Display variables
  echo "${CYAN_TEXT}${BOLD_TEXT}Project ID: ${PROJECT_ID}${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Region: ${REGION}${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Postgres VM Internal IP: ${POSTGRES_VM_INTERNAL_IP}${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Postgres VM External IP: ${POSTGRES_VM_EXTERNAL_IP}${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Cloud SQL Instance ID: ${CLOUDSQL_INSTANCE_ID}${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Qwiklabs User: ${QWIKLABS_USER}${RESET_FORMAT}"
}

# Task 1: Migrate PostgreSQL to Cloud SQL
task1() {
  task_header "1" "Migrate a stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance"
  
  # Enable required APIs
  echo "${CYAN_TEXT}${BOLD_TEXT}Enabling required APIs...${RESET_FORMAT}"
  execute_command "gcloud services enable datamigration.googleapis.com servicenetworking.googleapis.com"
  success_message "Required APIs enabled successfully"
  
  # Create a script to prepare PostgreSQL VM
  echo "${CYAN_TEXT}${BOLD_TEXT}Creating script to prepare PostgreSQL VM...${RESET_FORMAT}"
  cat > prepare_postgres.sh << 'EOF'
#!/bin/bash

# Update package list
sudo apt-get update -y

# Install pglogical extension
sudo apt-get install -y postgresql-13-pglogical

# Edit PostgreSQL configuration file
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/13/main/postgresql.conf
sudo sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'pglogical'/" /etc/postgresql/13/main/postgresql.conf
sudo sed -i "s/#wal_level = replica/wal_level = logical/" /etc/postgresql/13/main/postgresql.conf
echo "max_worker_processes = 10" | sudo tee -a /etc/postgresql/13/main/postgresql.conf
echo "max_replication_slots = 10" | sudo tee -a /etc/postgresql/13/main/postgresql.conf 
echo "max_wal_senders = 10" | sudo tee -a /etc/postgresql/13/main/postgresql.conf

# Edit pg_hba.conf file
echo "host    all    all    0.0.0.0/0    md5" | sudo tee -a /etc/postgresql/13/main/pg_hba.conf

# Restart PostgreSQL
sudo systemctl restart postgresql

# Create migration user
sudo -u postgres psql -c "CREATE USER \"Postgres Migration User\" WITH PASSWORD 'DMS_1s_cool!' SUPERUSER;"

# Connect to orders database and add primary keys
sudo -u postgres psql -d orders << SQL_COMMANDS
ALTER TABLE distribution_centers ADD PRIMARY KEY (id) IF NOT EXISTS;
ALTER TABLE inventory_items ADD PRIMARY KEY (id) IF NOT EXISTS;
ALTER TABLE order_items ADD PRIMARY KEY (id) IF NOT EXISTS;
ALTER TABLE products ADD PRIMARY KEY (id) IF NOT EXISTS;
ALTER TABLE users ADD PRIMARY KEY (id) IF NOT EXISTS;
SQL_COMMANDS

echo "PostgreSQL preparation completed successfully"
EOF

  # Copy & execute script on PostgreSQL VM
  echo "${CYAN_TEXT}${BOLD_TEXT}Copying and executing preparation script on PostgreSQL VM...${RESET_FORMAT}"
  execute_command "chmod +x prepare_postgres.sh"
  execute_command "gcloud compute scp prepare_postgres.sh postgres-vm:~/ --zone=${POSTGRES_VM_ZONE}"
  execute_command "gcloud compute ssh postgres-vm --zone=${POSTGRES_VM_ZONE} --command='bash ~/prepare_postgres.sh'"
  success_message "PostgreSQL VM prepared successfully"
  
  # For creating connection profile and migration job, we need to use manual steps
  manual_step "Create Database Migration Service connection profile in the Google Cloud Console:"
  echo "${YELLOW_TEXT}1. Navigate to Database Migration > Connection profiles${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Click 'CREATE PROFILE'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. Select PostgreSQL${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Fill in the following details:${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Connection profile name: postgres-source-profile${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Region: ${REGION}${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Host: ${POSTGRES_VM_INTERNAL_IP}${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Port: 5432${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Username: Postgres Migration User${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Password: DMS_1s_cool!${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. Click 'CREATE'${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi

  
  manual_step "Create a Database Migration Service job:"
  echo "${YELLOW_TEXT}1. Navigate to Database Migration > Migration jobs${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Click 'CREATE MIGRATION JOB'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. Set basic info:${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Migration job name: postgres-migration-job${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Migration job type: Continuous${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Source database engine: PostgreSQL${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Target database engine: Cloud SQL for PostgreSQL${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Region: ${REGION}${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Click 'SAVE & CONTINUE'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. Select your source connection profile and click 'SAVE & CONTINUE'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}6. Configure destination:${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Destination instance ID: ${CLOUDSQL_INSTANCE_ID}${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Password: supersecret!${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Database version: Cloud SQL for PostgreSQL 13${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Region: ${REGION}${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Enable both Public IP and Private IP${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- For Private IP: Use automatically allocated IP range${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Edition: Enterprise${RESET_FORMAT}"
  echo "   ${YELLOW_TEXT}- Machine type: 2 vCPU, 8GB memory${RESET_FORMAT}"
  echo "${YELLOW_TEXT}7. Click 'CREATE & CONTINUE'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}8. For connectivity: Select 'VPC peering' with default network${RESET_FORMAT}"
  echo "${YELLOW_TEXT}9. Click 'TEST' to verify connectivity${RESET_FORMAT}"
  echo "${YELLOW_TEXT}10. Click 'CREATE'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}11. Start the migration job by clicking 'START'${RESET_FORMAT}"
  
  echo "${CYAN_TEXT}${BOLD_TEXT}Wait for the continuous migration job to start replicating data...${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
}

# Task 2: Promote Cloud SQL to stand-alone instance
task2() {
  task_header "2" "Promote a Cloud SQL to be a stand-alone instance for reading and writing data"
  
  manual_step "Promote the Cloud SQL instance to a stand-alone instance:"
  echo "${YELLOW_TEXT}1. Navigate to Database Migration > Migration jobs${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Select your migration job 'postgres-migration-job'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. Click 'PROMOTE' to promote the Cloud SQL instance to a primary instance${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Click 'PROMOTE' in the confirmation dialog${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. Wait for the promotion to complete - status will update to 'Completed'${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  success_message "Cloud SQL instance promoted to stand-alone successfully"
}

# Task 3: Implement Cloud SQL for PostgreSQL IAM database authentication
task3() {
  task_header "3" "Implement Cloud SQL for PostgreSQL IAM database authentication"
  
  # Add postgres-vm external IP to allowed networks
  manual_step "Add postgres-vm's external IP to allowed networks:"
  echo "${YELLOW_TEXT}1. Navigate to SQL > ${CLOUDSQL_INSTANCE_ID} > Connections > Networking${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Under 'Public IP', click 'ADD A NETWORK'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. Add the following IP address: ${POSTGRES_VM_EXTERNAL_IP}${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Click 'DONE' and then 'SAVE'${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  # Create Cloud SQL IAM user
  manual_step "Create a Cloud SQL IAM user:"
  echo "${YELLOW_TEXT}1. Navigate to SQL > ${CLOUDSQL_INSTANCE_ID} > Users${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Click 'ADD USER ACCOUNT'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. Select 'Cloud IAM'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. For the principal, enter the USERNAME${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. Click 'ADD'${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  # Grant SELECT permission
  manual_step "Grant SELECT permission to IAM user:"
  echo "${YELLOW_TEXT}1. Navigate to SQL > ${CLOUDSQL_INSTANCE_ID} > Overview${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Click on 'Open Cloud Shell' under 'Connect to this instance'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. For the password, enter: supersecret!${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Connect to orders database using: \\c orders;${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. When prompted again, enter password: supersecret!${RESET_FORMAT}"
  echo "${YELLOW_TEXT}6. Run the following command to grant SELECT permission:${RESET_FORMAT}"
  echo "${YELLOW_TEXT}   GRANT SELECT ON orders TO \"Replace_Qwiklabs_User_Account_Name\";${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  # Test the permissions
  manual_step "Test the permissions with the following query:"
  echo "${YELLOW_TEXT}1. In the same Cloud Shell session, run:${RESET_FORMAT}"
  echo "${YELLOW_TEXT}   SELECT COUNT(*) FROM orders;${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Verify that you can see the results${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  success_message "Cloud SQL IAM authentication configured successfully"
}

# Task 4: Configure and test point-in-time recovery
task4() {
  task_header "4" "Configure and test point-in-time recovery"
  
  # Enable backups and point-in-time recovery
  manual_step "Enable backups and point-in-time recovery:"
  echo "${YELLOW_TEXT}1. Navigate to SQL > ${CLOUDSQL_INSTANCE_ID} > Overview${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Click 'EDIT'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. Go to 'Data Protection' section${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Check 'Enable point-in-time recovery'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. Set 'Transaction log retention' to the required days${RESET_FORMAT}"
  echo "${YELLOW_TEXT}6. Click 'SAVE'${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  # Note timestamp for point-in-time recovery
  echo "${CYAN_TEXT}${BOLD_TEXT}Current timestamp for point-in-time recovery:${RESET_FORMAT}"
  PITR_TIMESTAMP=$(date -u --rfc-3339=ns | sed -r 's/ /T/; s/\.([0-9]{3}).*/\.\1Z/')
  echo "${GREEN_TEXT}${BOLD_TEXT}${PITR_TIMESTAMP}${RESET_FORMAT}"
  echo "${YELLOW_TEXT}Please make a note of this timestamp for later use in point-in-time recovery${RESET_FORMAT}"
  
  # Make changes to the database
  manual_step "Make changes to the database after noting the timestamp:"
  echo "${YELLOW_TEXT}1. Navigate to SQL > ${CLOUDSQL_INSTANCE_ID} > Overview${RESET_FORMAT}"
  echo "${YELLOW_TEXT}2. Click on 'Open Cloud Shell' under 'Connect to this instance'${RESET_FORMAT}"
  echo "${YELLOW_TEXT}3. For the password, enter: supersecret!${RESET_FORMAT}"
  echo "${YELLOW_TEXT}4. Connect to orders database using: \\c orders;${RESET_FORMAT}"
  echo "${YELLOW_TEXT}5. When prompted again, enter password: supersecret!${RESET_FORMAT}"
  echo "${YELLOW_TEXT}6. Add a row to distribution_centers table with:${RESET_FORMAT}"
  echo "${YELLOW_TEXT}   INSERT INTO distribution_centers (id, name, latitude, longitude) VALUES (999, 'Test Center', 37.7749, -122.4194);${RESET_FORMAT}"

  echo "${BLUE_TEXT}${BOLD_TEXT}Have you completed the above steps? (y/n) ${RESET_FORMAT}"
  read -r connection_profile_created

  if [[ "$connection_profile_created" != "y" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Please complete the above tasks and run the script again ${RESET_FORMAT}"
  fi
  
  # Create clone using point-in-time recovery
  manual_step "Create a clone using point-in-time recovery:"
  echo "${YELLOW_TEXT}Execute the following command in Cloud Shell (substitute the timestamp you noted earlier):${RESET_FORMAT}"
  echo "${YELLOW_TEXT}gcloud sql instances clone ${CLOUDSQL_INSTANCE_ID} postgres-orders-pitr --project=${PROJECT_ID} --point-in-time=\"${PITR_TIMESTAMP}\"${RESET_FORMAT}"
  
  success_message "Point-in-time recovery configured and tested successfully"
}

# Main execution
main() {
  
  # Get variables
  get_variables
  
  # Execute tasks
  task1
  task2
  task3
  task4
}

# Execute main function
main

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
