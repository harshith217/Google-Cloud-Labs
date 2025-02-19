#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Welcome message
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo ""

# Step 1: Set the default compute zone
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Setting the default compute zone${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Set the default compute region
echo "${GREEN_TEXT}${BOLD_TEXT}Step 2: Setting the default compute region${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 3: Enable required Google Cloud services
echo "${CYAN_TEXT}${BOLD_TEXT}Step 3: Enabling required Google Cloud services${RESET_FORMAT}"
gcloud services enable servicenetworking.googleapis.com
gcloud services enable sqladmin.googleapis.com

# Step 4: Create a VPC Peering IP address range
echo "${BLUE_TEXT}${BOLD_TEXT}Step 4: Creating a VPC Peering IP address range${RESET_FORMAT}"
gcloud compute addresses create google-managed-services-default \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=24 \
    --network=default

sleep 30

# Step 5: Establish VPC Peering with the Google Cloud SQL service
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 5: Establishing VPC Peering with Google Cloud SQL${RESET_FORMAT}"
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --network=default \
    --ranges=google-managed-services-default

# Step 6: Create a Cloud SQL instance
echo "${RED_TEXT}${BOLD_TEXT}Step 6: Creating a Cloud SQL instance${RESET_FORMAT}"
gcloud sql instances create wordpress-db \
    --database-version=MYSQL_8_0 \
    --tier=db-custom-1-3840 \
    --region=$REGION \
    --storage-size=10GB \
    --storage-type=SSD \
    --root-password=awesome \
    --network=default \
    --no-assign-ip \
    --enable-google-private-path

# Step 7: Create a database within the Cloud SQL instance
echo "${CYAN_TEXT}${BOLD_TEXT}Step 7: Creating the 'wordpress' database${RESET_FORMAT}"
gcloud sql databases create wordpress \
  --instance=wordpress-db \
  --charset=utf8 \
  --collation=utf8_general_ci

# Step 8: Create a script to prepare the disk and Cloud SQL Proxy
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 8: Creating a script to prepare the disk and Cloud SQL Proxy${RESET_FORMAT}"
cat > prepare_disk.sh <<'EOF_END'

export PROJECT_ID=$(gcloud config get-value project)

export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy && chmod +x cloud_sql_proxy

export SQL_CONNECTION=$PROJECT_ID:$REGION:wordpress-db

./cloud_sql_proxy -instances=$SQL_CONNECTION=tcp:3306 &

EOF_END

# Step 9: Copy the script to the remote instance
echo "${GREEN_TEXT}${BOLD_TEXT}Step 9: Copying the script to the remote instance${RESET_FORMAT}"
gcloud compute scp prepare_disk.sh wordpress-proxy:/tmp \
  --project=$(gcloud config get-value project) --zone=$ZONE --quiet

# Step 10: Execute the script on the remote instance
echo "${BLUE_TEXT}${BOLD_TEXT}Step 10: Executing the script on the remote instance${RESET_FORMAT}"
gcloud compute ssh wordpress-proxy \
  --project=$(gcloud config get-value project) --zone=$ZONE --quiet \
  --command="bash /tmp/prepare_disk.sh"

echo "${CYAN_TEXT}${BOLD_TEXT}Process completed successfully!${RESET_FORMAT}"
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo