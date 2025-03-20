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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

cat /tmp/installhugo.sh

cd ~
/tmp/installhugo.sh

echo "${YELLOW_TEXT}${BOLD_TEXT}Retrieving project details...${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
sudo apt-get update -y
sudo apt-get install git -y
sudo apt-get install gh -y

echo "${YELLOW_TEXT}${BOLD_TEXT}Installing GitHub CLI...${RESET_FORMAT}"

curl -sS https://webi.sh/gh | sh
echo "${YELLOW_TEXT}${BOLD_TEXT}Authenticating GitHub CLI...${RESET_FORMAT}"

gh auth login
gh api user -q ".login"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo ${GITHUB_USERNAME}
echo ${USER_EMAIL}


echo "${YELLOW_TEXT}${BOLD_TEXT}Creating and cloning repository...${RESET_FORMAT}"

cd ~
gh repo create  my_hugo_site --private 
gh repo clone  my_hugo_site 

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting up Hugo site...${RESET_FORMAT}"

cd ~
/tmp/hugo new site my_hugo_site --force


cd ~/my_hugo_site
git clone \
  https://github.com/rhazdon/hugo-theme-hello-friend-ng.git themes/hello-friend-ng
echo 'theme = "hello-friend-ng"' >> config.toml


sudo rm -r themes/hello-friend-ng/.git
sudo rm themes/hello-friend-ng/.gitignore 


cd ~/my_hugo_site
/tmp/hugo server -D --bind 0.0.0.0 --port 8080

#----------------------------------------------
echo "${MAGENTA_TEXT}${BOLD_TEXT}Please Check ALL SCORES of TASK 1.${RESET_FORMAT}"
read -p "${CYAN_TEXT}${BOLD_TEXT}Have you checked all the scores of Task 1? (y/n): ${RESET_FORMAT}" CHECK_SCORES
if [[ "$CHECK_SCORES" != "y" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Please check all the scores of Task 1 and then run the script again.${RESET_FORMAT}"
fi
#----------------------------------------------
echo "${YELLOW_TEXT}${BOLD_TEXT}Retrieving project details again...${RESET_FORMAT}"

export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo "${YELLOW_TEXT}${BOLD_TEXT}Installing Firebase CLI...${RESET_FORMAT}"
curl -sL https://firebase.tools | bash

cd ~/my_hugo_site
firebase init


/tmp/hugo && firebase deploy

git config --global user.name "hugo"
git config --global user.email "hugo@blogger.com"

cd ~/my_hugo_site
echo "resources" >> .gitignore


git add .
git commit -m "Add app to GitHub Repository"
git push -u origin master


cd ~/my_hugo_site
cp /tmp/cloudbuild.yaml .

cat cloudbuild.yaml

echo $REGION
echo $PROJECT_ID

echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud Build connection...${RESET_FORMAT}"
gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID  --region=$REGION 

gcloud builds connections describe cloud-build-connection --region=$REGION 

#----------------------------------------------
echo "${MAGENTA_TEXT}${BOLD_TEXT}NOW FOLLOW VIDEO STEPS.${RESET_FORMAT}"
read -p "${CYAN_TEXT}${BOLD_TEXT}Have you completed the steps from video? (y/n): ${RESET_FORMAT}" CHECK_SCORES
if [[ "$CHECK_SCORES" != "y" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Please check all the scores of Task 1 and then run the script again.${RESET_FORMAT}"
fi
#----------------------------------------------


export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")


read -p "${CYAN_TEXT}${BOLD_TEXT}Enter your personal GITHUB_USERNAME : ${RESET_FORMAT}" GITHUB_USERNAME
echo $GITHUB_USERNAME


echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Cloud Build repository...${RESET_FORMAT}"
gcloud builds repositories create hugo-website-build-repository \
  --remote-uri="https://github.com/$GITHUB_USERNAME/my_hugo_site.git" \
  --connection="cloud-build-connection" --region=$REGION



echo "${YELLOW_TEXT}${BOLD_TEXT}Creating build trigger...${RESET_FORMAT}"
gcloud builds triggers create github --name="commit-to-master-branch1" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/hugo-website-build-repository \
   --build-config='cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
   --region=$REGION \
   --branch-pattern='^master$'



cd ~/my_hugo_site

sed -i "3c\title = 'Blogging with Hugo and Cloud Build'" config.toml



git add .
git commit -m "I updated the site title"
git push -u origin master

cd ~/my_hugo_site
cp /tmp/cloudbuild.yaml .

cat cloudbuild.yaml

echo $REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Submitting build...${RESET_FORMAT}"
gcloud builds submit --region=$REGION


sleep 30

echo $REGION

BUILD_ID=$(gcloud builds list --region=$REGION --format="value(ID)" --limit=1)
gcloud builds log $BUILD_ID --region=$REGION


gcloud builds log "$(gcloud builds list --region=$REGION --format='value(ID)' --limit=1)" | grep "Hosting URL"
BUILD_ID=$(gcloud builds list --region=$REGION --format="value(ID)" --limit=1)
gcloud builds log $BUILD_ID --region=$REGION


gcloud builds log "$(gcloud builds list --region=$REGION --format='value(ID)' --limit=1)" | grep "Hosting URL"


echo ""

echo $REGION

echo "" 


# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
