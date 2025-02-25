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
echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Step 1: Set environment variables
echo "${BOLD}${CYAN}Setting up environment variables${RESET}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region $REGION

# Step 2: Enable required services
echo "${BOLD}${YELLOW}Enabling necessary Google Cloud services${RESET}"
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    containeranalysis.googleapis.com

# Step 3: Create Artifact Registry repository
echo "${BOLD}${BLUE}Creating Artifact Registry repository${RESET}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION

# Step 4: Create GKE cluster
echo "${BOLD}${MAGENTA}Creating GKE Cluster${RESET}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

# Step 5: Install GitHub CLI
echo "${BOLD}${CYAN}Installing GitHub CLI${RESET}"
curl -sS https://webi.sh/gh | sh

# Step 6: Authenticate GitHub
echo "${BOLD}${GREEN} Authenticating with GitHub${RESET}"
gh auth login 
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}

# Step 7: Create GitHub Repositories
echo "${BOLD}${YELLOW}Creating GitHub repositories${RESET}"
gh repo create  hello-cloudbuild-app --private 

gh repo create  hello-cloudbuild-env --private

# Step 8: Clone Google Storage files
echo "${BOLD}${MAGENTA}Cloning source files${RESET}"
cd ~
mkdir hello-cloudbuild-app

gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app

cd ~/hello-cloudbuild-app

# Step 9: Update region values in files
echo "${BOLD}${CYAN}Updating region values in configuration files${RESET}"
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

# Step 10: Initialize git repository
echo "${BOLD}${GREEN}Initializing Git repository${RESET}"
git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
git branch -m master
git add . && git commit -m "initial commit"

# Step 11: Submit build to Cloud Build
echo "${BOLD}${BLUE}Submitting build to Cloud Build${RESET}"
COMMIT_ID="$(git rev-parse --short=7 HEAD)"

gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .

echo

echo "${BOLD}${BLUE}Click here to set up triggers: ${RESET}""https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID"

# Call function to check progress before proceeding
check_progress

# Step 12: Commit and push changes
echo "${BOLD}${MAGENTA}Pushing changes to GitHub${RESET}"
git add .

git commit -m "Type Any Commit Message here"

git push google master

cd ~

# Step 13: Create SSH Key for GitHub authentication
echo "${BOLD}${CYAN}Generating SSH key for GitHub${RESET}"
mkdir workingdir
cd workingdir

ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"

# Step 14: Store SSH key in Secret Manager
echo "${BOLD}${GREEN}Storing SSH key in Secret Manager${RESET}"
gcloud secrets create ssh_key_secret --replication-policy="automatic"

gcloud secrets versions add ssh_key_secret --data-file=id_github

# Step 15: Add SSH key to GitHub
echo "${BOLD}${BLUE}Adding SSH key to GitHub${RESET}"
GITHUB_TOKEN=$(gh auth token)

SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)

gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  /repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false

rm id_github*

# Step 16: Grant permissions
echo "${BOLD}${YELLOW}Granting IAM permissions${RESET}"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role=roles/secretmanager.secretAccessor

cd ~

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role=roles/container.developer

# Step 17: Clone environment repository
echo "${BOLD}${MAGENTA}Cloning environment repository${RESET}"
mkdir hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env

# Step 18: Modify files and push
echo "${BOLD}${CYAN}Modifying files and pushing to GitHub${RESET}"
cd hello-cloudbuild-env
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env
git branch -m master
git add . && git commit -m "initial commit"
git push google master

# Step 19: Checkout and modify deployment branch
echo "${BOLD}${GREEN}Configuring deployment pipeline${RESET}"
git checkout -b production

rm cloudbuild.yaml

curl -LO ENV-cloudbuild.yaml

mv ENV-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION-/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add .

git commit -m "Create cloudbuild.yaml for deployment"

git checkout -b candidate

git push google production

git push google candidate

# Step 20: Trigger CD pipeline
echo "${BOLD}${YELLOW}Triggering the CD pipeline${RESET}"
cd ~/hello-cloudbuild-app
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git add .
git commit -m "Adding known_host file."
git push google master

rm cloudbuild.yaml

curl -LO APP-cloudbuild.yaml

mv APP-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add cloudbuild.yaml

git commit -m "Trigger CD pipeline"

git push google master
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
echo -e "${BRIGHT_RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BRIGHT_BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo