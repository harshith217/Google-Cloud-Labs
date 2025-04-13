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

echo "${GREEN_TEXT}${BOLD_TEXT}Step 1: Displaying the contents of installhugo.sh file.${RESET_FORMAT}"
cat /tmp/installhugo.sh

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Moving to the home directory and executing installhugo.sh.${RESET_FORMAT}"
cd ~
/tmp/installhugo.sh

echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Setting up project environment variables.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 4: Updating system and installing required packages.${RESET_FORMAT}"
sudo apt-get update
sudo apt-get install git
sudo apt-get install gh

echo "${CYAN_TEXT}${BOLD_TEXT}Step 5: Installing GitHub CLI using webi.sh.${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Authenticating GitHub CLI.${RESET_FORMAT}"
gh auth login
gh api user -q ".login"

echo "${GREEN_TEXT}${BOLD_TEXT}Step 7: Configuring GitHub user details.${RESET_FORMAT}"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 8: Creating and cloning the Hugo site repository.${RESET_FORMAT}"
cd ~
gh repo create  my_hugo_site --private 
gh repo clone  my_hugo_site 

echo "${BLUE_TEXT}${BOLD_TEXT}Step 9: Initializing the Hugo site.${RESET_FORMAT}"
cd ~
/tmp/hugo new site my_hugo_site --force

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 10: Cloning the Hugo theme.${RESET_FORMAT}"
cd ~/my_hugo_site
git clone \
    https://github.com/rhazdon/hugo-theme-hello-friend-ng.git themes/hello-friend-ng
echo 'theme = "hello-friend-ng"' >> config.toml

echo "${CYAN_TEXT}${BOLD_TEXT}Step 11: Removing unnecessary Git files from the theme.${RESET_FORMAT}"
sudo rm -r themes/hello-friend-ng/.git
sudo rm themes/hello-friend-ng/.gitignore 

echo "${RED_TEXT}${BOLD_TEXT}Step 12: Starting the Hugo server in the background.${RESET_FORMAT}"
nohup /tmp/hugo server -D --bind 0.0.0.0 --port 8080 > hugo.log 2>&1 &

echo "Hugo server is running in the background with PID: $!"
echo "To stop it, run: kill $!"

function check_progress {
        while true; do
                echo
                echo -n "${RED_TEXT}${BOLD_TEXT}Have you checked your progress up to Task 1? (Y/N): ${RESET_FORMAT}"
                read -r user_input
                if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
                        echo
                        echo "${GREEN_TEXT}${BOLD_TEXT}Proceeding to the next steps...${RESET_FORMAT}"
                        echo
                        break
                elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
                        echo
                        echo "${RED_TEXT}${BOLD_TEXT}Please check your progress up to Task 1 and then press Y to continue.${RESET_FORMAT}"
                else
                        echo
                        echo "${MAGENTA_TEXT}${BOLD_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
                fi
        done
}

check_progress

echo "${GREEN_TEXT}${BOLD_TEXT}Step 13: Installing Firebase CLI.${RESET_FORMAT}"
curl -sL https://firebase.tools | bash

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 14: Initializing the Firebase project.${RESET_FORMAT}"
cd ~/my_hugo_site
firebase init

echo "${BLUE_TEXT}${BOLD_TEXT}Step 15: Deploying the Hugo site to Firebase.${RESET_FORMAT}"
/tmp/hugo && firebase deploy

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 16: Configuring Git user details for commits.${RESET_FORMAT}"
git config --global user.name "hugo"
git config --global user.email "hugo@blogger.com"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 17: Ignoring the resources directory and pushing to GitHub.${RESET_FORMAT}"
cd ~/my_hugo_site
echo "resources" >> .gitignore

git add .
git commit -m "Add app to GitHub Repository"
git push -u origin master

echo "${RED_TEXT}${BOLD_TEXT}Step 18: Copying and displaying cloudbuild.yaml.${RESET_FORMAT}"
cd ~/my_hugo_site
cp /tmp/cloudbuild.yaml .

cat cloudbuild.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}Step 19: Creating a Cloud Build GitHub connection.${RESET_FORMAT}"
gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID  --region=$REGION

echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 20: Open the Cloud Build Repositories Console.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Use the link below to verify the connection.${RESET_FORMAT}"
echo "https://console.cloud.google.com/cloud-build/repositories/2nd-gen?project=$PROJECT_ID"

function check_progress {
        while true; do
                echo
                echo -n "${YELLOW_TEXT}${BOLD_TEXT}Have you installed the Cloud Build GitHub App? (Y/N): ${RESET_FORMAT}"
                read -r user_input
                if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
                        echo
                        echo "${GREEN_TEXT}${BOLD_TEXT}Proceeding to the next steps...${RESET_FORMAT}"
                        echo
                        break
                elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
                        echo
                        echo "${RED_TEXT}${BOLD_TEXT}Please install the Cloud Build GitHub App and then press Y to continue.${RESET_FORMAT}"
                else
                        echo
                        echo "${MAGENTA_TEXT}${BOLD_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
                fi
        done
}

check_progress

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 21: Describing the Cloud Build connection.${RESET_FORMAT}"
gcloud builds connections describe cloud-build-connection --region=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 22: Creating a Cloud Build repository connection.${RESET_FORMAT}"
gcloud builds repositories create hugo-website-build-repository \
    --remote-uri="https://github.com/${GITHUB_USERNAME}/my_hugo_site.git" \
    --connection="cloud-build-connection" --region=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Step 23: Creating a Cloud Build trigger.${RESET_FORMAT}"
gcloud builds triggers create github --name="commit-to-master-branch1" \
     --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/hugo-website-build-repository \
     --build-config='cloudbuild.yaml' \
     --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
     --region=$REGION \
     --branch-pattern='^master$'

echo "${RED_TEXT}${BOLD_TEXT}Step 24: Updating the site title in config.toml.${RESET_FORMAT}"
sed -i "s/^title = .*/title = 'Blogging with Hugo and Cloud Build'/" config.toml

echo "${GREEN_TEXT}${BOLD_TEXT}Step 25: Adding, committing, and pushing changes to Git.${RESET_FORMAT}"
git add .
git commit -m "I updated the site title"
git push -u origin master

sleep 15

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 26: Listing all builds in Cloud Build.${RESET_FORMAT}"
gcloud builds list --region=$REGION

echo "${BLUE_TEXT}${BOLD_TEXT}Step 27: Fetching logs for the latest Cloud Build.${RESET_FORMAT}"
gcloud builds log --region=$REGION $(gcloud builds list --format='value(ID)' --filter=$(git rev-parse HEAD) --region=$REGION)

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 28: Sleeping for 15 seconds to allow logs to update.${RESET_FORMAT}"
sleep 15

echo "${CYAN_TEXT}${BOLD_TEXT}Step 29: Extracting the Hosting URL from Cloud Build logs.${RESET_FORMAT}"
gcloud builds log "$(gcloud builds list --format='value(ID)' --filter=$(git rev-parse HEAD) --region=$REGION)" --region=$REGION | grep "Hosting URL"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo

echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
