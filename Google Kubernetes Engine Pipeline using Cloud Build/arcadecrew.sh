#!/bin/bash

# --- Text Formatting Variables ---
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

# --- Script Start ---
clear

echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}🚀       INITIATING EXECUTION...     🚀${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# --- Authenticate and Configure GCP ---
echo "${CYAN_TEXT}${BOLD_TEXT}➡️ Verifying authenticated GCP account...${RESET_FORMAT}"
gcloud auth list

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⚙️ Fetching and setting default GCP zone and region...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🆔 Fetching GCP Project ID and Number...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "${GREEN_TEXT}Project ID set to: ${BOLD_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo "${GREEN_TEXT}Project Number set to: ${BOLD_TEXT}${PROJECT_NUMBER}${RESET_FORMAT}"
echo "${GREEN_TEXT}Default Region set to: ${BOLD_TEXT}${REGION}${RESET_FORMAT}"
echo "${GREEN_TEXT}Default Zone set to: ${BOLD_TEXT}${ZONE}${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Setting default compute region in gcloud config...${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo
echo "${CYAN_TEXT}${BOLD_TEXT}☁️ Enabling necessary GCP APIs (Container, Cloud Build, Secret Manager, Container Analysis)...${RESET_FORMAT}"
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    containeranalysis.googleapis.com

echo
echo "${CYAN_TEXT}${BOLD_TEXT}📦 Creating Artifact Registry Docker repository 'my-repository'...${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION

echo
echo "${CYAN_TEXT}${BOLD_TEXT}☸️ Creating GKE cluster 'hello-cloudbuild'...${RESET_FORMAT}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

# --- Configure GitHub ---
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🐙 Installing GitHub CLI (gh)...${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh 
echo "${GREEN_TEXT}${BOLD_TEXT}✅ GitHub CLI installed.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Authenticating with GitHub. Please follow the prompts...${RESET_FORMAT}"
gh auth login
echo "${GREEN_TEXT}${BOLD_TEXT}✅ GitHub authentication successful.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}👤 Fetching GitHub username and configuring Git...${RESET_FORMAT}"
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo "${GREEN_TEXT}GitHub Username: ${BOLD_TEXT}${GITHUB_USERNAME}${RESET_FORMAT}"
echo "${GREEN_TEXT}GitHub Email: ${BOLD_TEXT}${USER_EMAIL}${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}➕ Creating private GitHub repository 'hello-cloudbuild-app'...${RESET_FORMAT}"
gh repo create  hello-cloudbuild-app --private 
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Repository 'hello-cloudbuild-app' created.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}➕ Creating private GitHub repository 'hello-cloudbuild-env'...${RESET_FORMAT}"
gh repo create  hello-cloudbuild-env --private
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Repository 'hello-cloudbuild-env' created.${RESET_FORMAT}"

# --- Setup Application Repository ---
echo
echo "${CYAN_TEXT}${BOLD_TEXT}📁 Setting up the 'hello-cloudbuild-app' directory and content...${RESET_FORMAT}"
cd ~
mkdir hello-cloudbuild-app
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app

cd ~/hello-cloudbuild-app
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Application directory created and populated.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Updating configuration files in 'hello-cloudbuild-app' with region: ${REGION}...${RESET_FORMAT}"
# Re-export REGION just in case, though it should persist
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Configuration files updated.${RESET_FORMAT}"

# Re-export PROJECT_ID just in case
PROJECT_ID=$(gcloud config get-value project)

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💾 Initializing Git repository for 'hello-cloudbuild-app' and making the first commit...${RESET_FORMAT}"
git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
git branch -m master
git add . && git commit -m "initial commit"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Git repository initialized and initial commit made.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}☁️ Building the initial Docker image using Cloud Build...${RESET_FORMAT}"
cd ~/hello-cloudbuild-app

COMMIT_ID="$(git rev-parse --short=7 HEAD)"

gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Initial Docker image build submitted.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏫ Pushing 'hello-cloudbuild-app' to GitHub...${RESET_FORMAT}"
cd ~/hello-cloudbuild-app
# Note: The previous commit added everything, this section might be redundant
# unless changes were made between the commit and the build. Adding a safety commit.
git add .

git commit -m "Type Any Commit Message here"

git push google master
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Application code pushed to GitHub.${RESET_FORMAT}"

# --- Setup SSH Key for Cloud Build ---
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Generating SSH key pair for Cloud Build to access the environment repository...${RESET_FORMAT}"
cd ~
mkdir workingdir
cd workingdir
ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ SSH key pair generated.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔒 Storing the private SSH key in GCP Secret Manager...${RESET_FORMAT}"
gcloud secrets create ssh_key_secret --replication-policy="automatic"

gcloud secrets versions add ssh_key_secret --data-file=id_github
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Private SSH key stored securely.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🐙 Adding the public SSH key as a deploy key to 'hello-cloudbuild-env' repository on GitHub...${RESET_FORMAT}"
GITHUB_TOKEN=$(gh auth token)

SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)

gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  /repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Public SSH key added to GitHub repository.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Cleaning up local SSH key files...${RESET_FORMAT}"
rm id_github*
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Local SSH key files removed.${RESET_FORMAT}"

# --- Grant Permissions ---
echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔐 Granting Compute Engine default service account access to the SSH key secret...${RESET_FORMAT}"
# Re-export PROJECT_NUMBER just in case
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role=roles/secretmanager.secretAccessor
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Secret Accessor role granted.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔐 Granting Cloud Build service account permissions to deploy to GKE (Kubernetes Engine Developer role)...${RESET_FORMAT}"
cd ~
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role=roles/container.developer
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Container Developer role granted.${RESET_FORMAT}"

# --- Setup Environment Repository ---
echo
echo "${CYAN_TEXT}${BOLD_TEXT}📁 Setting up the 'hello-cloudbuild-env' directory and content...${RESET_FORMAT}"
mkdir hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env
cd hello-cloudbuild-env
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Environment directory created and populated.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Updating configuration files in 'hello-cloudbuild-env' with region: ${REGION}...${RESET_FORMAT}"
# Re-export REGION just in case
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Configuration files updated.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Adding GitHub's SSH host key to known_hosts for secure Git operations...${RESET_FORMAT}"
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github
echo "${GREEN_TEXT}${BOLD_TEXT}✅ known_hosts file created.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💾 Initializing Git repository for 'hello-cloudbuild-env', adding known_hosts, and making the first commit...${RESET_FORMAT}"
git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env
git branch -m master
git add . && git commit -m "initial commit"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Git repository initialized and initial commit made.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏫ Pushing 'hello-cloudbuild-env' initial commit to GitHub...${RESET_FORMAT}"
git push google master
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Environment code pushed to GitHub master branch.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🌿 Creating and checking out 'production' branch...${RESET_FORMAT}"
git checkout -b production
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Switched to new branch 'production'.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Replacing default Cloud Build config with environment-specific 'env-cloudbuild.yaml'...${RESET_FORMAT}"
rm cloudbuild.yaml

wget https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/env-cloudbuild.yaml

mv env-cloudbuild.yaml cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Build config updated for environment repo.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Updating 'cloudbuild.yaml' in 'production' branch with region (${REGION}) and GitHub username (${GITHUB_USERNAME})...${RESET_FORMAT}"
# Re-export REGION just in case
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
sed -i "s/REGION-/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}✅ cloudbuild.yaml updated.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💾 Committing the environment-specific Cloud Build configuration...${RESET_FORMAT}"
git add .
git commit -m "Create cloudbuild.yaml for deployment"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Changes committed.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🌿 Creating 'candidate' branch based on 'production'...${RESET_FORMAT}"
git checkout -b candidate
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Switched to new branch 'candidate'.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏫ Pushing 'production' and 'candidate' branches to GitHub...${RESET_FORMAT}"
git push google production
git push google candidate
echo "${GREEN_TEXT}${BOLD_TEXT}✅ 'production' and 'candidate' branches pushed.${RESET_FORMAT}"

# --- Finalize Application Repository Setup ---
echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏪ Switching back to the application repository directory...${RESET_FORMAT}"
cd ~/hello-cloudbuild-app

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Adding GitHub's SSH host key to known_hosts in the application repository...${RESET_FORMAT}"
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github
echo "${GREEN_TEXT}${BOLD_TEXT}✅ known_hosts file created.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💾 Committing known_hosts file...${RESET_FORMAT}"
git add .
git commit -m "Adding known_host file."
echo "${GREEN_TEXT}${BOLD_TEXT}✅ known_hosts file committed.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏫ Pushing known_hosts update to GitHub...${RESET_FORMAT}"
git push google master
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Changes pushed to master branch.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔄 Replacing default Cloud Build config with application-specific 'app-cloudbuild.yaml'...${RESET_FORMAT}"
rm cloudbuild.yaml
wget https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/app-cloudbuild.yaml
mv app-cloudbuild.yaml cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Build config updated for application repo.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔧 Updating 'cloudbuild.yaml' in 'master' branch with region (${REGION}) and GitHub username (${GITHUB_USERNAME})...${RESET_FORMAT}"
# Re-export REGION just in case
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
sed -i "s/REGION/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}✅ cloudbuild.yaml updated.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💾 Committing the application-specific Cloud Build configuration...${RESET_FORMAT}"
git add cloudbuild.yaml
git commit -m "Trigger CD pipeline"
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Changes committed.${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⏫ Pushing final application Cloud Build config update to GitHub...${RESET_FORMAT}"
git push google master
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Final changes pushed to master branch.${RESET_FORMAT}"

# --- Final Instructions ---
echo
echo "${YELLOW_TEXT}1. Go to the Google Cloud Console to create the Cloud Build Triggers.${RESET_FORMAT}"
echo "${YELLOW_TEXT}   Direct Link: ${UNDERLINE_TEXT}https://console.cloud.google.com/cloud-build/triggers?project=$PROJECT_ID${RESET_FORMAT}"
echo "${YELLOW_TEXT}2. Follow VIDEO to configure the triggers for both repositories.${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the setup? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

