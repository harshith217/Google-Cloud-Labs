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

function check_progress {
  while true; do
    echo
    echo -n "${YELLOW_TEXT}${BOLD_TEXT}❓ Have you configured the Cloud Build triggers: 'hello-cloudbuild' & ['hello-cloudbuild-deploy' (for region $REGION) with the '^candidate$'] pattern? (Y/N): ${RESET_FORMAT}"
    read -r user_input
    if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
      echo
      echo "${GREEN_TEXT}${BOLD_TEXT}✅ Awesome! Moving forward to the next steps...${RESET_FORMAT}"
      echo
      break
    elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
      echo
      echo "${RED_TEXT}${BOLD_TEXT}🛑 Action Required: Please ensure 'hello-cloudbuild' & 'hello-cloudbuild-deploy' triggers are created in $REGION with the '^candidate$' pattern. Then, press Y to continue.${RESET_FORMAT}"
    else
      echo
      echo "${MAGENTA_TEXT}${BOLD_TEXT}⚠️ Oops! Invalid input. Please respond with Y or N.${RESET_FORMAT}"
    fi
  done
}

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD_TEXT}🚀 Launching the Automated Setup Process...${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}⚙️ Step 1: Configuring Essential Environment Variables${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Fetching your Google Cloud Project ID... 🆔${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${BLUE_TEXT}${BOLD_TEXT}Retrieving your Google Cloud Project Number... 🔢${RESET_FORMAT}"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "${BLUE_TEXT}${BOLD_TEXT}Identifying the default Google Cloud Region for operations... 🌍${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${BLUE_TEXT}${BOLD_TEXT}Setting '$REGION' as the default compute region in your gcloud configuration... 🛠️${RESET_FORMAT}"
gcloud config set compute/region $REGION

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🛠️ Step 2: Activating Required Google Cloud Services${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Enabling Container Engine, Cloud Build, Secret Manager, and Container Analysis APIs... 💡${RESET_FORMAT}"
gcloud services enable container.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  containeranalysis.googleapis.com

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📦 Step 3: Setting Up Artifact Registry Repository${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a Docker repository named 'my-repository' in '$REGION'... 🖼️${RESET_FORMAT}"
gcloud artifacts repositories create my-repository \
  --repository-format=docker \
  --location=$REGION

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🚢 Step 4: Provisioning Google Kubernetes Engine Cluster${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a GKE cluster named 'hello-cloudbuild' with 1 node in '$REGION'... This might take a few minutes. ⚙️${RESET_FORMAT}"
gcloud container clusters create hello-cloudbuild --num-nodes 1 --region $REGION

echo
echo "${CYAN_TEXT}${BOLD_TEXT}💻 Step 5: Installing GitHub CLI (gh)${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Downloading and installing the latest GitHub CLI... 📥${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔑 Step 6: Authenticating with GitHub${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Please follow the prompts to log in to your GitHub account... 👤${RESET_FORMAT}"
gh auth login
echo "${BLUE_TEXT}${BOLD_TEXT}Fetching your GitHub username... 📛${RESET_FORMAT}"
GITHUB_USERNAME=$(gh api user -q ".login")
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Git with your GitHub username: '${GITHUB_USERNAME}'... ✍️${RESET_FORMAT}"
git config --global user.name "${GITHUB_USERNAME}"
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Git with your email: '${USER_EMAIL}' (Ensure the USER_EMAIL variable is set in your environment if not prompted)... 📧${RESET_FORMAT}"
git config --global user.email "${USER_EMAIL}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Confirming GitHub Username: ${RESET_FORMAT}"
echo ${GITHUB_USERNAME}
echo "${YELLOW_TEXT}${BOLD_TEXT}Confirming User Email: ${RESET_FORMAT}"
echo ${USER_EMAIL}

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📚 Step 7: Creating GitHub Repositories${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a new private GitHub repository named 'hello-cloudbuild-app'... 📦${RESET_FORMAT}"
gh repo create  hello-cloudbuild-app --private
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a new private GitHub repository named 'hello-cloudbuild-env'... 🌳${RESET_FORMAT}"
gh repo create  hello-cloudbuild-env --private

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📂 Step 8: Preparing Application Source Code${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Navigating to the home directory... 🏠${RESET_FORMAT}"
cd ~
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a directory for the application: 'hello-cloudbuild-app'... 📁${RESET_FORMAT}"
mkdir hello-cloudbuild-app
echo "${BLUE_TEXT}${BOLD_TEXT}Copying application source files from Google Cloud Storage into 'hello-cloudbuild-app'... 📥${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-app
echo "${BLUE_TEXT}${BOLD_TEXT}Changing directory to '~/hello-cloudbuild-app'... 🚶${RESET_FORMAT}"
cd ~/hello-cloudbuild-app

echo
echo "${CYAN_TEXT}${BOLD_TEXT}✍️ Step 9: Customizing Configuration Files with Region '$REGION'${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild.yaml'... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild-delivery.yaml'... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild-trigger-cd.yaml'... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'kubernetes.yaml.tpl'... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🌱 Step 10: Initializing Git for Application Repository${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Initializing a new Git repository in the current directory... ✨${RESET_FORMAT}"
git init
echo "${BLUE_TEXT}${BOLD_TEXT}Configuring Git credential helper to use gcloud.sh for authentication... 🔑${RESET_FORMAT}"
git config credential.helper gcloud.sh
echo "${BLUE_TEXT}${BOLD_TEXT}Adding remote 'google' pointing to 'https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app'... 🔗${RESET_FORMAT}"
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-app
echo "${BLUE_TEXT}${BOLD_TEXT}Renaming the current branch to 'master'... 🌿${RESET_FORMAT}"
git branch -m master
echo "${BLUE_TEXT}${BOLD_TEXT}Staging all changes and making an initial commit with message 'initial commit'... 💾${RESET_FORMAT}"
git add . && git commit -m "initial commit"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Step 11: Submitting Initial Build to Cloud Build${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Getting the short commit ID for tagging the Docker image... 🏷️${RESET_FORMAT}"
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the current directory to Cloud Build to build and tag the image as '${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}'... 🏗️${RESET_FORMAT}"
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/my-repository/hello-cloudbuild:${COMMIT_ID}" .

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🔔 Important: You might need to set up Cloud Build triggers manually. Visit the link below if needed:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://console.cloud.google.com/cloud-build/triggers;region=global/add?project=$PROJECT_ID${RESET_FORMAT}"

check_progress

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📤 Step 12: Pushing Application Code to GitHub${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Staging all new and modified files for the next commit... ➕${RESET_FORMAT}"
git add .
echo "${BLUE_TEXT}${BOLD_TEXT}Committing changes with a placeholder message. Feel free to change this message if running interactively... 💬${RESET_FORMAT}"
git commit -m "Type Any Commit Message here"
echo "${BLUE_TEXT}${BOLD_TEXT}Pushing the 'master' branch to the 'google' remote (GitHub repository 'hello-cloudbuild-app')... 🚀${RESET_FORMAT}"
git push google master
echo "${BLUE_TEXT}${BOLD_TEXT}Returning to the home directory... 🏠${RESET_FORMAT}"
cd ~

echo
echo "${CYAN_TEXT}${BOLD_TEXT}🔑 Step 13: Generating SSH Key for Environment Repository Access${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Creating a temporary 'workingdir' directory for SSH key generation... 📁${RESET_FORMAT}"
mkdir workingdir
echo "${GREEN_TEXT}${BOLD_TEXT}Navigating into 'workingdir'... 🚶${RESET_FORMAT}"
cd workingdir
echo "${GREEN_TEXT}${BOLD_TEXT}Generating a new RSA 4096-bit SSH key pair (id_github) for '${USER_EMAIL}' without a passphrase. This key will be used for the environment repository... 🔐${RESET_FORMAT}"
ssh-keygen -t rsa -b 4096 -N '' -f id_github -C "${USER_EMAIL}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔒 Step 14: Storing Private SSH Key in Google Cloud Secret Manager${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a new secret named 'ssh_key_secret' in Secret Manager with automatic replication... 🤫${RESET_FORMAT}"
gcloud secrets create ssh_key_secret --replication-policy="automatic"
echo "${BLUE_TEXT}${BOLD_TEXT}Adding the private SSH key ('id_github') as a new version to the 'ssh_key_secret'... ➕${RESET_FORMAT}"
gcloud secrets versions add ssh_key_secret --data-file=id_github

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔗 Step 15: Adding Public SSH Key to GitHub Environment Repository${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Retrieving GitHub authentication token for API access... 🪙${RESET_FORMAT}"
GITHUB_TOKEN=$(gh auth token)
echo "${GREEN_TEXT}${BOLD_TEXT}Reading the content of the public SSH key ('id_github.pub')... 📜${RESET_FORMAT}"
SSH_KEY_CONTENT=$(cat ~/workingdir/id_github.pub)
echo "${GREEN_TEXT}${BOLD_TEXT}Adding the public SSH key as a deploy key (with write access) to the 'hello-cloudbuild-env' repository on GitHub... 🚀${RESET_FORMAT}"
gh api --method POST -H "Accept: application/vnd.github.v3+json" \
  /repos/${GITHUB_USERNAME}/hello-cloudbuild-env/keys \
  -f title="SSH_KEY" \
  -f key="$SSH_KEY_CONTENT" \
  -F read_only=false
echo "${GREEN_TEXT}${BOLD_TEXT}Cleaning up local SSH key files ('id_github' and 'id_github.pub') from 'workingdir'... 🧹${RESET_FORMAT}"
rm id_github*

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}🛡️ Step 16: Configuring Necessary IAM Permissions${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Granting the 'Secret Manager Secret Accessor' role to the Compute Engine default service account (${PROJECT_NUMBER}-compute@developer.gserviceaccount.com)... 📜${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
--role=roles/secretmanager.secretAccessor
echo "${GREEN_TEXT}${BOLD_TEXT}Navigating back to the home directory... 🏠${RESET_FORMAT}"
cd ~
echo "${GREEN_TEXT}${BOLD_TEXT}Granting the 'Kubernetes Engine Developer' role to the Cloud Build service account (${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com)... 🛠️${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
--member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role=roles/container.developer

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🌳 Step 17: Preparing Environment Configuration Repository Files${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a directory for the environment configuration: 'hello-cloudbuild-env'... 📁${RESET_FORMAT}"
mkdir hello-cloudbuild-env
echo "${BLUE_TEXT}${BOLD_TEXT}Copying environment configuration files from Google Cloud Storage into 'hello-cloudbuild-env'... 📥${RESET_FORMAT}"
gcloud storage cp -r gs://spls/gsp1077/gke-gitops-tutorial-cloudbuild/* hello-cloudbuild-env

echo
echo "${CYAN_TEXT}${BOLD_TEXT}✍️ Step 18: Customizing and Pushing Environment Configuration to GitHub${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Changing directory to '~/hello-cloudbuild-env'... 🚶${RESET_FORMAT}"
cd hello-cloudbuild-env
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild.yaml' for the environment repository... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild-delivery.yaml' for the environment repository... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild-delivery.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild-trigger-cd.yaml' for the environment repository... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" cloudbuild-trigger-cd.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in 'kubernetes.yaml.tpl' for the environment repository... 📝${RESET_FORMAT}"
sed -i "s/us-central1/$REGION/g" kubernetes.yaml.tpl
echo "${GREEN_TEXT}${BOLD_TEXT}Scanning and adding GitHub's RSA key to a 'known_hosts.github' file for SSH access... 🔑${RESET_FORMAT}"
ssh-keyscan -t rsa github.com > known_hosts.github
echo "${GREEN_TEXT}${BOLD_TEXT}Setting execute permission on 'known_hosts.github' (Note: This is unusual for a known_hosts file, kept from original script)... ⚙️${RESET_FORMAT}"
chmod +x known_hosts.github
echo "${GREEN_TEXT}${BOLD_TEXT}Initializing a new Git repository for the environment configuration... ✨${RESET_FORMAT}"
git init
echo "${GREEN_TEXT}${BOLD_TEXT}Configuring Git credential helper to use gcloud.sh... 🔑${RESET_FORMAT}"
git config credential.helper gcloud.sh
echo "${GREEN_TEXT}${BOLD_TEXT}Adding remote 'google' pointing to 'https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env'... 🔗${RESET_FORMAT}"
git remote add google https://github.com/${GITHUB_USERNAME}/hello-cloudbuild-env
echo "${GREEN_TEXT}${BOLD_TEXT}Renaming the current branch to 'master'... 🌿${RESET_FORMAT}"
git branch -m master
echo "${GREEN_TEXT}${BOLD_TEXT}Staging all changes and making an 'initial commit' for the environment repository... 💾${RESET_FORMAT}"
git add . && git commit -m "initial commit"
echo "${GREEN_TEXT}${BOLD_TEXT}Pushing the 'master' branch of the environment repository to GitHub... 🚀${RESET_FORMAT}"
git push google master

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🌿 Step 19: Setting Up Deployment Branches for Environment Repository${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Creating and switching to a new branch named 'production'... 🏭${RESET_FORMAT}"
git checkout -b production
echo "${BLUE_TEXT}${BOLD_TEXT}Removing the existing 'cloudbuild.yaml' from the 'production' branch... 🗑️${RESET_FORMAT}"
rm cloudbuild.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}Downloading the environment-specific Cloud Build configuration ('ENV-cloudbuild.yaml')... 📥${RESET_FORMAT}"
curl -LO https://raw.githubusercontent.com/ArcadeCrew/Google-Cloud-Labs/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/ENV-cloudbuild.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}Renaming 'ENV-cloudbuild.yaml' to 'cloudbuild.yaml' in the 'production' branch... 🔄${RESET_FORMAT}"
mv ENV-cloudbuild.yaml cloudbuild.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}Updating region placeholder in 'cloudbuild.yaml' to '$REGION'... 🌍${RESET_FORMAT}"
sed -i "s/REGION-/$REGION/g" cloudbuild.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}Updating GitHub username placeholder in 'cloudbuild.yaml' to '${GITHUB_USERNAME}'... 👤${RESET_FORMAT}"
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml
echo "${BLUE_TEXT}${BOLD_TEXT}Staging changes in the 'production' branch... ➕${RESET_FORMAT}"
git add .
echo "${BLUE_TEXT}${BOLD_TEXT}Committing the Cloud Build configuration for the deployment pipeline to the 'production' branch... 💬${RESET_FORMAT}"
git commit -m "Create cloudbuild.yaml for deployment"
echo "${BLUE_TEXT}${BOLD_TEXT}Creating and switching to a new branch named 'candidate' from 'production'... 🌱${RESET_FORMAT}"
git checkout -b candidate
echo "${BLUE_TEXT}${BOLD_TEXT}Pushing the 'production' branch to the 'google' remote (GitHub)... 🚀${RESET_FORMAT}"
git push google production
echo "${BLUE_TEXT}${BOLD_TEXT}Pushing the 'candidate' branch to the 'google' remote (GitHub)... 🚀${RESET_FORMAT}"
git push google candidate

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}▶️ Step 20: Triggering the Continuous Deployment (CD) Pipeline${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Navigating back to the application repository '~/hello-cloudbuild-app'... 🚶${RESET_FORMAT}"
cd ~/hello-cloudbuild-app
echo "${GREEN_TEXT}${BOLD_TEXT}Scanning and adding GitHub's RSA key to 'known_hosts.github' in the application repository... 🔑${RESET_FORMAT}"
ssh-keyscan -t rsa github.com > known_hosts.github
echo "${GREEN_TEXT}${BOLD_TEXT}Setting execute permission on 'known_hosts.github' in app repo (Note: Unusual, kept from original script)... ⚙️${RESET_FORMAT}"
chmod +x known_hosts.github
echo "${GREEN_TEXT}${BOLD_TEXT}Staging the 'known_hosts.github' file... ➕${RESET_FORMAT}"
git add .
echo "${GREEN_TEXT}${BOLD_TEXT}Committing the 'known_hosts.github' file... 💬${RESET_FORMAT}"
git commit -m "Adding known_host file."
echo "${GREEN_TEXT}${BOLD_TEXT}Pushing the 'known_hosts.github' commit to the 'master' branch of the application repository... 🚀${RESET_FORMAT}"
git push google master
echo "${GREEN_TEXT}${BOLD_TEXT}Removing the existing 'cloudbuild.yaml' from the application repository... 🗑️${RESET_FORMAT}"
rm cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Downloading the application-specific Cloud Build configuration ('APP-cloudbuild.yaml')... 📥${RESET_FORMAT}"
curl -LO https://github.com/ArcadeCrew/Google-Cloud-Labs/raw/refs/heads/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/APP-cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Renaming 'APP-cloudbuild.yaml' to 'cloudbuild.yaml' in the application repository... 🔄${RESET_FORMAT}"
mv APP-cloudbuild.yaml cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating region placeholder in the application 'cloudbuild.yaml' to '$REGION'... 🌍${RESET_FORMAT}"
sed -i "s/REGION/$REGION/g" cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Updating GitHub username placeholder in the application 'cloudbuild.yaml' to '${GITHUB_USERNAME}'... 👤${RESET_FORMAT}"
sed -i "s/GITHUB-USERNAME/${GITHUB_USERNAME}/g" cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Staging the new 'cloudbuild.yaml' for the application repository... ➕${RESET_FORMAT}"
git add cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Committing changes to 'cloudbuild.yaml' to trigger the CD pipeline... 💬${RESET_FORMAT}"
git commit -m "Trigger CD pipeline"
echo "${GREEN_TEXT}${BOLD_TEXT}Pushing changes to the 'master' branch of the application repository to initiate the CD pipeline... 🚀${RESET_FORMAT}"
git push google master

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
