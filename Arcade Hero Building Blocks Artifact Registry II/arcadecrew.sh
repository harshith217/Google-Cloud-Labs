#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Please configure the repository settings below before proceeding:${RESET_FORMAT}"
read -p "${YELLOW_TEXT}   Enter Repository Name [${BOLD_TEXT}container-registry${RESET_FORMAT}${YELLOW_TEXT}]: ${RESET_FORMAT}" -i "container-registry" REPO_NAME
REPO_NAME=${REPO_NAME:-container-registry} # Fallback if -i is not supported or input is cleared

read -p "${YELLOW_TEXT}   Enter Region [${BOLD_TEXT}us-central1${RESET_FORMAT}${YELLOW_TEXT}]: ${RESET_FORMAT}" -i "us-central1" REGION
REGION=${REGION:-us-central1} # Fallback

read -p "${YELLOW_TEXT}   Enter Cleanup Policy Name [${BOLD_TEXT}Grandfather${RESET_FORMAT}${YELLOW_TEXT}]: ${RESET_FORMAT}" -i "Grandfather" POLICY_NAME
POLICY_NAME=${POLICY_NAME:-Grandfather} # Fallback

read -p "${YELLOW_TEXT}   Enter Number of Versions to Keep [${BOLD_TEXT}3${RESET_FORMAT}${YELLOW_TEXT}]: ${RESET_FORMAT}" -i "3" KEEP_COUNT
KEEP_COUNT=${KEEP_COUNT:-3} # Fallback

REPO_FORMAT="DOCKER"
ADD_CLEANUP_POLICY=true

echo
echo "${BLUE_TEXT}${BOLD_TEXT}⚙️  Fetching your current Google Cloud Project ID...${RESET_FORMAT}"
PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}✅ Project ID identified as: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔑 Enabling the Artifact Registry API for your project...${RESET_FORMAT}"
echo "${YELLOW_TEXT}   This allows the project to use Artifact Registry services.${RESET_FORMAT}"
gcloud services enable artifactregistry.googleapis.com --project="$PROJECT_ID" --quiet
echo "${GREEN_TEXT}✅ Artifact Registry API enabled successfully.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🏗️  Creating the Artifact Registry repository named '${REPO_NAME}'...${RESET_FORMAT}"
echo "${YELLOW_TEXT}   Region: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
echo "${YELLOW_TEXT}   Format: ${BOLD_TEXT}$REPO_FORMAT${RESET_FORMAT}"
gcloud artifacts repositories create "$REPO_NAME" \
  --project="$PROJECT_ID" \
  --repository-format="$REPO_FORMAT" \
  --location="$REGION" \
  --description="Repository created by script" --quiet
echo "${GREEN_TEXT}✅ Repository '${REPO_NAME}' created successfully.${RESET_FORMAT}"
echo

if [[ "$ADD_CLEANUP_POLICY" == true ]]; then
  echo "${BLUE_TEXT}${BOLD_TEXT}🧹 Adding a cleanup policy named '${POLICY_NAME}' to the repository...${RESET_FORMAT}"
  echo "${YELLOW_TEXT}   This policy will keep the ${BOLD_TEXT}$KEEP_COUNT${YELLOW_TEXT} most recent versions.${RESET_FORMAT}"

  POLICY_FILE=$(mktemp --suffix=.yaml)
  trap "rm -f $POLICY_FILE" EXIT

  cat << EOF > "$POLICY_FILE"
policies:
  - name: "$POLICY_NAME"
    action:
      type: KEEP
    condition:
      mostRecentVersions: $KEEP_COUNT
EOF
  echo "${YELLOW_TEXT}   Applying the policy from the temporary file: ${BOLD_TEXT}$POLICY_FILE${RESET_FORMAT}"
  gcloud artifacts repositories set-cleanup-policies "$REPO_NAME" \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --policy-file="$POLICY_FILE" --quiet

  echo "${GREEN_TEXT}✅ Cleanup policy '${POLICY_NAME}' applied successfully.${RESET_FORMAT}"

else
  echo "${YELLOW_TEXT}${BOLD_TEXT}🚫 Skipping the creation of a cleanup policy as requested.${RESET_FORMAT}"
fi

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
