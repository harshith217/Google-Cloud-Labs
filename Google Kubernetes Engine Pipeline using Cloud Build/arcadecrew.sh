#!/bin/bash

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

echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

function check_progress {
        while true; do
                echo
                echo "${GREEN_TEXT}${BOLD_TEXT}***********************************************${RESET_FORMAT}"
                echo "${GREEN_TEXT}${BOLD_TEXT}              DO NOT PRESS CTRL+C              ${RESET_FORMAT}"
                echo "${GREEN_TEXT}${BOLD_TEXT}***********************************************${RESET_FORMAT}"
                echo
                echo "${YELLOW_TEXT}${BOLD_TEXT}Please ensure you have configured the following Cloud Build triggers:${RESET_FORMAT}"
                echo "${CYAN_TEXT}  - Trigger 1 for repository: ${WHITE_TEXT}hello-cloudbuild${RESET_FORMAT}"
                echo "${CYAN_TEXT}  - Trigger 2 for repository: ${WHITE_TEXT}hello-cloudbuild-deploy ($REGION)${RESET_FORMAT}"
                echo "${CYAN_TEXT}  - Both triggers should be set for branches matching: ${WHITE_TEXT}^candidate$${RESET_FORMAT}"
                echo
                echo -n "${RED_TEXT}${BOLD_TEXT}Have you completed this step? (Y/N): ${RESET_FORMAT}"
                read -r user_input
                if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
                        echo
                        echo "${BOLD_TEXT}${GREEN_TEXT}Proceeding to next steps...${RESET_FORMAT}"
                        echo
                        break
                elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
                        echo
                        echo "${BOLD_TEXT}${RED_TEXT}Please set up hello-cloudbuild & hello-cloudbuild-deploy ($REGION) with ^candidate$ triggers before continuing.${RESET_FORMAT}"
                else
                        echo
                        echo "${BOLD_TEXT}${MAGENTA_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
                fi
        done
}

# Step 1: Set environment variables
echo "${BOLD_TEXT}${CYAN_TEXT}Configuring environment variables${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region $REGION

# Step 2: Enable required services
echo "${BOLD_TEXT}${YELLOW_TEXT}Activating required Google Cloud services${RESET_FORMAT}"
gcloud services enable container.googleapis.com \
        cloudbuild.googleapis.com \
        secretmanager.googleapis.com \
        containeranalysis.googleapis.com

# Step 3: Create Artifact Registry repository
echo "${BOLD_TEXT}${BLUE_TEXT}Setting up Artifact Registry repository${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION

# Step 4: Create GKE cluster
echo "${BOLD_TEXT}${MAGENTA_TEXT}Deploying GKE Cluster${RESET_FORMAT}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

# Step 5: Install GitHub CLI
echo "${BOLD_TEXT}${CYAN_TEXT}Installing GitHub command-line interface${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh

# Step 6: Authenticate GitHub
echo "${BOLD_TEXT}${GREEN_TEXT}Establishing GitHub authentication${RESET_FORMAT}"
gh auth login 
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}

# Step 7: Create GitHub Repositories
echo "${BOLD_TEXT}${YELLOW_TEXT}Creating required GitHub repositories${RESET_FORMAT}"
gh repo create  hello-cloudbuild-app --private 

gh repo create  hello-cloudbuild-env --private

# Step 8: Clone Google Storage files
echo "${BOLD_TEXT}${MAGENTA_TEXT}Retrieving source files${RESET_FORMAT}"
cd ~
mkdir hello-cloudbuild-app

gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app

cd ~/hello-cloudbuild-app

# Step 9: Update region values in files
echo "${BOLD_TEXT}${CYAN_TEXT}Updating regional configurations in files${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

# Step 10: Initialize git repository
echo "${BOLD_TEXT}${GREEN_TEXT}Setting up Git repository${RESET_FORMAT}"
git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
git branch -m master
git add . && git commit -m "initial commit"

# Step 11: Submit build to Cloud Build
echo "${BOLD_TEXT}${BLUE_TEXT}Submitting application to Cloud Build${RESET_FORMAT}"
COMMIT_ID="$(git rev-parse --short=7 HEAD)"

gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .

echo

echo "${BOLD_TEXT}${BLUE_TEXT}Navigate to this URL to configure triggers: ${RESET_FORMAT}""https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID"

# Call function to check progress before proceeding
check_progress

# Step 12: Commit and push changes
echo "${BOLD_TEXT}${MAGENTA_TEXT}Uploading changes to GitHub${RESET_FORMAT}"
git add .

git commit -m "Type Any Commit Message here"

git push google master

cd ~

# Step 13: Create SSH Key for GitHub authentication
echo "${BOLD_TEXT}${CYAN_TEXT}Creating SSH key for GitHub access${RESET_FORMAT}"
mkdir workingdir
cd workingdir

ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"

# Step 14: Store SSH key in Secret Manager
echo "${BOLD_TEXT}${GREEN_TEXT}Securely storing SSH key in Secret Manager${RESET_FORMAT}"
gcloud secrets create ssh_key_secret --replication-policy="automatic"

gcloud secrets versions add ssh_key_secret --data-file=id_github

# Step 15: Add SSH key to GitHub
echo "${BOLD_TEXT}${BLUE_TEXT}Registering SSH key with GitHub${RESET_FORMAT}"
GITHUB_TOKEN=$(gh auth token)

SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)

gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  /repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false

rm id_github*

# Step 16: Grant permissions
echo "${BOLD_TEXT}${YELLOW_TEXT}Assigning necessary IAM permissions${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role=roles/secretmanager.secretAccessor

cd ~

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role=roles/container.developer

# Step 17: Clone environment repository
echo "${BOLD_TEXT}${MAGENTA_TEXT}Cloning environment configuration repository${RESET_FORMAT}"
mkdir hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env

# Step 18: Modify files and push
echo "${BOLD_TEXT}${CYAN_TEXT}Updating and pushing configuration files to GitHub${RESET_FORMAT}"
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
echo "${BOLD_TEXT}${GREEN_TEXT}Setting up deployment pipeline configuration${RESET_FORMAT}"
git checkout -b production

rm cloudbuild.yaml

curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/ENV-cloudbuild.yaml

mv ENV-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION-/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add .

git commit -m "Create cloudbuild.yaml for deployment"

git checkout -b candidate

git push google production

git push google candidate

# Step 20: Trigger CD pipeline
echo "${BOLD_TEXT}${YELLOW_TEXT}Initiating the CD pipeline process${RESET_FORMAT}"
cd ~/hello-cloudbuild-app
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git add .
git commit -m "Adding known_host file."
git push google master

rm cloudbuild.yaml

curl -LO raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/APP-cloudbuild.yaml

mv APP-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add cloudbuild.yaml

git commit -m "Trigger CD pipeline"

git push google master

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe to my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
