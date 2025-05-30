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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📊 STEP 1: Configuring Project Environment Variables${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
gcloud config set compute/region $REGION

echo "${GREEN_TEXT}${BOLD_TEXT}📋 STEP 2: Activating Essential Google Cloud Services${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Enabling Container, Cloud Build, Secret Manager & Security Analysis APIs...${RESET_FORMAT}"
gcloud services enable container.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  containeranalysis.googleapis.com

echo "${BLUE_TEXT}${BOLD_TEXT}📦 STEP 3: Setting Up Artifact Registry Repository${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🏗️ Creating a Docker repository to store your container images...${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}☸️ STEP 4: Deploying Google Kubernetes Engine Cluster${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🚢 Launching a single-node GKE cluster for your applications...${RESET_FORMAT}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

echo "${CYAN_TEXT}${BOLD_TEXT}🔧 STEP 5: Installing GitHub Command Line Interface${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}📥 Downloading and setting up GitHub CLI for repository management...${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh

echo "${GREEN_TEXT}${BOLD_TEXT}🔐 STEP 6: GitHub Authentication Process${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎯 Please follow the prompts to authenticate with your GitHub account...${RESET_FORMAT}"
gh auth login 
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}

echo "${YELLOW_TEXT}${BOLD_TEXT}🏭 STEP 7: Creating GitHub Repository Infrastructure${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Setting up private repositories for application and environment code...${RESET_FORMAT}"
gh repo create  hello-cloudbuild-app --private 

gh repo create  hello-cloudbuild-env --private

echo "${MAGENTA_TEXT}${BOLD_TEXT}📂 STEP 8: Downloading Source Code Templates${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}⬇️ Fetching pre-configured files from Google Cloud Storage...${RESET_FORMAT}"
cd ~
mkdir hello-cloudbuild-app

gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app

cd ~/hello-cloudbuild-app

echo "${CYAN_TEXT}${BOLD_TEXT}⚙️ STEP 9: Customizing Configuration Files${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}🔄 Updating region-specific settings in your deployment files...${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

echo "${GREEN_TEXT}${BOLD_TEXT}🔄 STEP 10: Initializing Version Control System${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}📋 Setting up Git repository and pushing initial codebase...${RESET_FORMAT}"
git init
git config credential.helper gcloud.sh
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
git branch -m master
git add . && git commit -m "initial commit"

echo "${BLUE_TEXT}${BOLD_TEXT}🔨 STEP 11: Building Container Image${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}🐳 Submitting build job to Cloud Build service...${RESET_FORMAT}"
COMMIT_ID="$(git rev-parse --short=7 HEAD)"

gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .

echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}🌐 CLICK THIS LINK TO ACCESS TRIGGER CREATION PAGE:${RESET_FORMAT}"
echo "${BLUE_TEXT}https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID${RESET_FORMAT}"

while true; do
    echo
    echo "${CYAN_TEXT}${BOLD_TEXT}┌─────────────────────────────────────────────────────────────┐${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}│                 TRIGGER CREATION REQUIRED                  │${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}├─────────────────────────────────────────────────────────────┤${RESET_FORMAT}"
    echo "${WHITE_TEXT}${BOLD_TEXT}│  Please create the following triggers:                     │${RESET_FORMAT}"
    echo "${WHITE_TEXT}│                                                             │${RESET_FORMAT}"
    echo "${YELLOW_TEXT}│  📋 Trigger 1: hello-cloudbuild                            │${RESET_FORMAT}"
    echo "${WHITE_TEXT}│                                                             │${RESET_FORMAT}"
    echo "${YELLOW_TEXT}│  📋 Trigger 2: hello-cloudbuild-deploy                     │${RESET_FORMAT}"
    echo "${WHITE_TEXT}│     ├─ Region: ${CYAN_TEXT}${REGION}${WHITE_TEXT}                                    │${RESET_FORMAT}"
    echo "${WHITE_TEXT}│     └─ Branch Pattern: ${GREEN_TEXT}^candidate$${WHITE_TEXT}                      │${RESET_FORMAT}"
    echo "${CYAN_TEXT}${BOLD_TEXT}└─────────────────────────────────────────────────────────────┘${RESET_FORMAT}"
    echo
    echo -n "${BOLD_TEXT}${YELLOW_TEXT}Have you completed the trigger creation? (Y/N): ${RESET_FORMAT}"
    read -r user_input
    if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
      echo
      echo "${BOLD_TEXT}${GREEN_TEXT}Proceeding to the next steps...${RESET_FORMAT}"
      echo
      break
    elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
      echo
      echo "${BOLD_TEXT}${RED_TEXT}Please create the required triggers and then press Y to continue.${RESET_FORMAT}"
    else
      echo
      echo "${BOLD_TEXT}${MAGENTA_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
    fi
  done

echo "${MAGENTA_TEXT}${BOLD_TEXT}📤 STEP 12: Publishing Code to Remote Repository${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Committing changes and pushing to GitHub repository...${RESET_FORMAT}"
git add .

git commit -m "Type Any Commit Message here"

git push google master

cd ~

echo "${CYAN_TEXT}${BOLD_TEXT}🔑 STEP 13: Generating SSH Authentication Key${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}🛡️ Creating secure SSH key pair for GitHub repository access...${RESET_FORMAT}"
mkdir workingdir
cd workingdir

ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"

echo "${GREEN_TEXT}${BOLD_TEXT}🗄️ STEP 14: Securing SSH Key in Secret Manager${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🔐 Storing private key securely in Google Cloud Secret Manager...${RESET_FORMAT}"
gcloud secrets create ssh_key_secret --replication-policy="automatic"

gcloud secrets versions add ssh_key_secret --data-file=id_github

echo "${BLUE_TEXT}${BOLD_TEXT}🔗 STEP 15: Registering SSH Key with GitHub${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}📝 Adding public key to your GitHub repository for secure access...${RESET_FORMAT}"
GITHUB_TOKEN=$(gh auth token)

SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)

gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  /repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false

rm id_github*

echo "${YELLOW_TEXT}${BOLD_TEXT}🔒 STEP 16: Configuring IAM Security Permissions${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}👥 Granting necessary service account permissions for secure operations...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role=roles/secretmanager.secretAccessor

cd ~

gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role=roles/container.developer

echo "${MAGENTA_TEXT}${BOLD_TEXT}🌱 STEP 17: Setting Up Environment Repository${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}📁 Cloning environment configuration files for deployment setup...${RESET_FORMAT}"
mkdir hello-cloudbuild-env
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env

echo "${CYAN_TEXT}${BOLD_TEXT}📝 STEP 18: Customizing Environment Configuration${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}⚙️ Updating environment files and establishing Git repository connection...${RESET_FORMAT}"
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

echo "${GREEN_TEXT}${BOLD_TEXT}🌿 STEP 19: Establishing Deployment Pipeline Branches${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}🔄 Creating production and candidate branches for GitOps workflow...${RESET_FORMAT}"
git checkout -b production

rm cloudbuild.yaml

curl -LO https://github.com/ArcadeCrew/Google-Cloud-Labs/raw/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/ENV-cloudbuild.yaml

mv ENV-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION-/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add .

git commit -m "Create cloudbuild.yaml for deployment"

git checkout -b candidate

git push google production

git push google candidate

echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 STEP 20: Activating Continuous Deployment Pipeline${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}⚡ Triggering automated deployment workflow and finalizing setup...${RESET_FORMAT}"
cd ~/hello-cloudbuild-app
ssh-keyscan -t rsa github.com > known_hosts.github
chmod +x known_hosts.github

git add .
git commit -m "Adding known_host file."
git push google master

rm cloudbuild.yaml

curl -LO https://github.com/ArcadeCrew/Google-Cloud-Labs/raw/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/APP-cloudbuild.yaml

mv APP-cloudbuild.yaml cloudbuild.yaml

sed -i "s/REGION/$REGION/g" cloudbuild.yaml
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml

git add cloudbuild.yaml

git commit -m "Trigger CD pipeline"

git push google master

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
