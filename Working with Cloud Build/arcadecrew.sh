#!/bin/bash

# Bright Foreground Colors
BRIGHT_BLACK_TEXT=$'\033[0;90m'
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

# Start of the script
echo
echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Display instructions for the user
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 1: Authenticating with GCP...${RESET_FORMAT}"
gcloud auth list

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 2: Setting the default region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${BRIGHT_BLUE_TEXT}Default region set to: ${REGION}${RESET_FORMAT}"

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 3: Enabling required APIs...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 4: Creating a quickstart script...${RESET_FORMAT}"
cat > quickstart.sh <<EOF_CP
#!/bin/sh
echo "Hello, world! The time is \$(date)."
EOF_CP

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 5: Creating a Dockerfile...${RESET_FORMAT}"
cat > Dockerfile <<EOF_CP
FROM alpine
COPY quickstart.sh /
CMD ["/quickstart.sh"]
EOF_CP

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 6: Making the script executable...${RESET_FORMAT}"
chmod +x quickstart.sh

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 7: Creating a Docker repository...${RESET_FORMAT}"
gcloud artifacts repositories create quickstart-docker-repo --repository-format=docker \
    --location="$REGION" --description="Docker repository"

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 8: Building and submitting the Docker image...${RESET_FORMAT}"
gcloud builds submit --tag "$REGION"-docker.pkg.dev/${DEVSHELL_PROJECT_ID}/quickstart-docker-repo/quickstart-image:tag1

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 9: Creating a Cloud Build configuration file...${RESET_FORMAT}"
cat > cloudbuild.yaml <<EOF_CP
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', 'YourRegionHere-docker.pkg.dev/\$PROJECT_ID/quickstart-docker-repo/quickstart-image:tag1', '.' ]
images:
- 'YourRegionHere-docker.pkg.dev/\$PROJECT_ID/quickstart-docker-repo/quickstart-image:tag1'
EOF_CP

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 10: Updating the region in the Cloud Build configuration...${RESET_FORMAT}"
echo $REGION
sed -i "s/YourRegionHere/$REGION/g" cloudbuild.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 11: Displaying the updated Cloud Build configuration...${RESET_FORMAT}"
cat cloudbuild.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 12: Submitting the Cloud Build job...${RESET_FORMAT}"
gcloud builds submit --config cloudbuild.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 13: Updating the quickstart script...${RESET_FORMAT}"
cat > quickstart.sh <<EOF_CP
#!/bin/sh
if [ -z "$1" ]
then
	echo "Hello, world! The time is $(date)."
	exit 0
else
	exit 1
fi
EOF_CP

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 14: Creating a second Cloud Build configuration file...${RESET_FORMAT}"
cat > cloudbuild2.yaml <<EOF_CP
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: [ 'build', '-t', 'YourRegionHere-docker.pkg.dev/\$PROJECT_ID/quickstart-docker-repo/quickstart-image:tag1', '.' ]
- name: 'YourRegionHere-docker.pkg.dev/\$PROJECT_ID/quickstart-docker-repo/quickstart-image:tag1'
  args: ['fail']
images:
- 'YourRegionHere-docker.pkg.dev/\$PROJECT_ID/quickstart-docker-repo/quickstart-image:tag1'
EOF_CP

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 15: Updating the region in the second Cloud Build configuration...${RESET_FORMAT}"
sed -i "s/YourRegionHere/$REGION/g" cloudbuild2.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 16: Displaying the updated second Cloud Build configuration...${RESET_FORMAT}"
cat cloudbuild2.yaml

echo
echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Step 17: Submitting the second Cloud Build job...${RESET_FORMAT}"
gcloud builds submit --config cloudbuild2.yaml

echo

# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${BRIGHT_RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo