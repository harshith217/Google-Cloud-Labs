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

# Function to display a progress bar for sleep
function show_progress {
  local duration=$1
  local message=${2:-"⏳ Waiting"}
  local width=40
  local delay=0.1
  local spinstr='⠏⠧⠹⠼'
  local cur=0
  # Calculate total steps accurately using awk
  local steps=$(awk "BEGIN {print int($duration / $delay)}")
  # Ensure steps is at least 1 to avoid division by zero
  steps=$(( steps > 0 ? steps : 1 ))

  echo -n "${CYAN_TEXT}${BOLD_TEXT}${message}: ${RESET_FORMAT}"
  # Draw the initial bar structure
  printf "["
  printf "%${width}s" "" # Print empty bar background
  printf "] 0%% %c" "${spinstr:0:1}"
  # Move cursor back to the beginning of the progress bar line
  printf "\r"

  # Start the progress loop
  echo -n "${CYAN_TEXT}${BOLD_TEXT}${message}: ${RESET_FORMAT}["
  while [ $cur -lt $steps ]; do
    # Calculate current progress width
    local current_width=$(awk "BEGIN {print int($cur * $width / $steps)}")
    # Calculate percentage
    local percent=$(awk "BEGIN {print int($cur * 100 / $steps)}")
    # Get the spinner character
    local spinchar=${spinstr:$(($cur % ${#spinstr})):1}

    # Print the filled part of the bar
    printf "%${current_width}s" '' | tr ' ' '█'
    # Print the empty part of the bar
    printf "%-$((width - current_width))s" ''
    # Print the closing bracket, percentage, and spinner
    printf "] %d%% %c" $percent $spinchar
    # Move cursor back to the beginning of the line for the next update
    printf "\r"
    # Print the bar prefix again for the next iteration (overwrites previous percentage/spinner)
    echo -n "${CYAN_TEXT}${BOLD_TEXT}${message}: ${RESET_FORMAT}["


    sleep $delay
    cur=$((cur + 1))
  done

  # Print the final completed bar
  printf "%${width}s" '' | tr ' ' '█'
  printf "] 100%% ✅\n"
  echo "${GREEN_TEXT}${BOLD_TEXT}Completed.${RESET_FORMAT}"
}


clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Displaying installhugo.sh contents...${RESET_FORMAT}"
cat /tmp/installhugo.sh

echo "${YELLOW_TEXT}${BOLD_TEXT}🏠 Moving to home directory and running installhugo.sh...${RESET_FORMAT}"
cd ~
/tmp/installhugo.sh

echo "${BLUE_TEXT}${BOLD_TEXT}🔧 Setting project environment variables...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${BLUE_TEXT}${BOLD_TEXT}Project ID: ${YELLOW_TEXT}${BOLD_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Project Number: ${YELLOW_TEXT}${BOLD_TEXT}${PROJECT_NUMBER}${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Region: ${YELLOW_TEXT}${BOLD_TEXT}${REGION}${RESET_FORMAT}"


echo "${MAGENTA_TEXT}${BOLD_TEXT}🔄 Updating system and installing Git & GitHub CLI...${RESET_FORMAT}"
sudo apt-get update
sudo apt-get install git -y
sudo apt-get install gh -y

echo "${CYAN_TEXT}${BOLD_TEXT}☁️ Installing GitHub CLI via webi.sh...${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh
export PATH=$HOME/.local/bin:$PATH # Ensure gh is in PATH

echo "${YELLOW_TEXT}${BOLD_TEXT}🔑 Authenticating GitHub CLI...${RESET_FORMAT}"
gh auth login
gh api user -q ".login"

echo "${GREEN_TEXT}${BOLD_TEXT}👤 Configuring GitHub user details...${RESET_FORMAT}"
GITHUB_USERNAME=$(gh api user -q ".login")
git config --global user.name "${GITHUB_USERNAME}"
# Set a placeholder email - Git requires an email, but it doesn't have to be the user's real one for this script
git config --global user.email "${GITHUB_USERNAME}@users.noreply.github.com"
echo "${GREEN_TEXT}${BOLD_TEXT}GitHub Username: ${YELLOW_TEXT}${BOLD_TEXT}${GITHUB_USERNAME}${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}GitHub Email set to placeholder: ${YELLOW_TEXT}${BOLD_TEXT}${GITHUB_USERNAME}@users.noreply.github.com${RESET_FORMAT}"

echo "${YELLOW_TEXT}${BOLD_TEXT}📦 Creating and cloning Hugo site repository...${RESET_FORMAT}"
cd ~
gh repo create my_hugo_site --private --source=. --push
gh repo clone my_hugo_site

echo "${BLUE_TEXT}${BOLD_TEXT}✨ Initializing new Hugo site...${RESET_FORMAT}"
cd ~
/tmp/hugo new site my_hugo_site --force

echo "${MAGENTA_TEXT}${BOLD_TEXT}🎨 Cloning Hugo theme into site...${RESET_FORMAT}"
cd ~/my_hugo_site
git clone \
  https://github.com/rhazdon/hugo-theme-hello-friend-ng.git themes/hello-friend-ng
echo 'theme = "hello-friend-ng"' >> config.toml

echo "${CYAN_TEXT}${BOLD_TEXT}🧹 Cleaning up theme Git files...${RESET_FORMAT}"
sudo rm -rf themes/hello-friend-ng/.git
sudo rm -f themes/hello-friend-ng/.gitignore

echo "${RED_TEXT}${BOLD_TEXT}🌐 Starting Hugo server in background...${RESET_FORMAT}"
nohup /tmp/hugo server -D --bind 0.0.0.0 --port 8080 > hugo.log 2>&1 &
HUGO_PID=$!
echo "${RED_TEXT}${BOLD_TEXT}Hugo server running (PID: ${YELLOW_TEXT}${BOLD_TEXT}${HUGO_PID}${RESET_FORMAT}). Log: ${YELLOW_TEXT}${BOLD_TEXT}hugo.log${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}To stop: kill ${YELLOW_TEXT}${BOLD_TEXT}${HUGO_PID}${RESET_FORMAT}"

function check_progress {
    local prompt_message=$1
    local task_name=$2
    while true; do
        echo
        echo -n "${YELLOW_TEXT}${BOLD_TEXT}${prompt_message} (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${GREEN_TEXT}${BOLD_TEXT}✅ Great! Proceeding...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED_TEXT}${BOLD_TEXT}✋ Please complete ${task_name} and then press Y to continue.${RESET_FORMAT}"
        else
            echo
            echo "${MAGENTA_TEXT}${BOLD_TEXT}❓ Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

echo
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}     CHECK PROGRESS TILL TASK 1 ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo

check_progress "Have you checked your progress up to Task 1?" "Task 1"

echo "${GREEN_TEXT}${BOLD_TEXT}🔥 Installing Firebase CLI...${RESET_FORMAT}"
curl -sL https://firebase.tools | bash

echo "${YELLOW_TEXT}${BOLD_TEXT}⚙️ Initializing Firebase project in site directory...${RESET_FORMAT}"
cd ~/my_hugo_site
firebase init

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Building and deploying Hugo site via Firebase...${RESET_FORMAT}"
/tmp/hugo && firebase deploy

echo "${MAGENTA_TEXT}${BOLD_TEXT}✍️ Configuring Git user details for commits...${RESET_FORMAT}"
git config --global user.name "hugo-builder"
git config --global user.email "hugo-builder@example.com"

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Ignoring resources directory and pushing initial site to GitHub...${RESET_FORMAT}"
cd ~/my_hugo_site
echo "resources/" >> .gitignore

git add .
git commit -m "Initial Hugo site setup"
git push -u origin master

echo "${RED_TEXT}${BOLD_TEXT}📑 Copying cloudbuild.yaml and displaying its content...${RESET_FORMAT}"
cd ~/my_hugo_site
cp /tmp/cloudbuild.yaml .
echo "--- cloudbuild.yaml content ---"
cat cloudbuild.yaml
echo "-------------------------------"


echo "${GREEN_TEXT}${BOLD_TEXT}🔗 Creating Cloud Build GitHub connection...${RESET_FORMAT}"
gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID --region=$REGION

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🔗 Open Cloud Build Repositories Console: ${UNDERLINE_TEXT}https://console.cloud.google.com/cloud-build/repositories/2nd-gen?project=${PROJECT_ID}${RESET_FORMAT}"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}       NOW FOLLOW VIDEO STEPS ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}************************************${RESET_FORMAT}"
echo

check_progress "Have you installed the Cloud Build GitHub App and authorized it?" "Cloud Build GitHub App installation"

echo "${YELLOW_TEXT}${BOLD_TEXT}ℹ️ Describing Cloud Build connection details...${RESET_FORMAT}"
gcloud builds connections describe cloud-build-connection --region=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}➕ Creating Cloud Build repository connection...${RESET_FORMAT}"
gcloud builds repositories create hugo-website-build-repository \
  --remote-uri="https://github.com/${GITHUB_USERNAME}/my_hugo_site.git" \
  --connection="cloud-build-connection" --region=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT} TRIGGER Creating Cloud Build trigger for master branch...${RESET_FORMAT}"
gcloud builds triggers create github --name="commit-to-master-branch1" \
   --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/hugo-website-build-repository \
   --build-config='cloudbuild.yaml' \
   --service-account=projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
   --region=$REGION \
   --branch-pattern='^master$'

echo "${RED_TEXT}${BOLD_TEXT}✏️ Updating site title in config.toml...${RESET_FORMAT}"
sed -i "s/^title = .*/title = 'Blogging with Hugo and Cloud Build'/" config.toml

echo "${GREEN_TEXT}${BOLD_TEXT}💾 Adding, committing, and pushing title change to Git...${RESET_FORMAT}"
git add .
git commit -m "Update site title via script"
git push -u origin master

show_progress 15 "⏱️ Allowing time for Cloud Build to trigger"

echo "${YELLOW_TEXT}${BOLD_TEXT}📋 Listing recent Cloud Builds...${RESET_FORMAT}"
gcloud builds list --region=$REGION

echo "${BLUE_TEXT}${BOLD_TEXT}📜 Fetching logs for the latest Cloud Build triggered by the title change...${RESET_FORMAT}"
LATEST_BUILD_ID=$(gcloud builds list --format='value(ID)' --filter="trigger_id:$(gcloud builds triggers list --filter='name=commit-to-master-branch1' --region=$REGION --format='value(id)')" --sort-by=~finishTime --limit=1 --region=$REGION)
if [ -n "$LATEST_BUILD_ID" ]; then
    echo "${BLUE_TEXT}${BOLD_TEXT}Logs for Build ID: ${YELLOW_TEXT}${BOLD_TEXT}${LATEST_BUILD_ID}${RESET_FORMAT}"
    gcloud builds log --region=$REGION "$LATEST_BUILD_ID"
else
    echo "${RED_TEXT}${BOLD_TEXT}Could not find the latest build for the trigger. Checking generic latest build...${RESET_FORMAT}"
    gcloud builds log --region=$REGION $(gcloud builds list --format='value(ID)' --filter=$(git rev-parse HEAD) --region=$REGION --limit=1 --sort-by=~finishTime)
fi


show_progress 15 "⏱️ Allowing a moment for logs to fully populate"

echo "${CYAN_TEXT}${BOLD_TEXT}🌐 Extracting Hosting URL from latest Cloud Build logs...${RESET_FORMAT}"
if [ -n "$LATEST_BUILD_ID" ]; then
    gcloud builds log "$LATEST_BUILD_ID" --region=$REGION | grep "Hosting URL"
else
     echo "${RED_TEXT}${BOLD_TEXT}Cannot extract URL without a specific build ID. Please check logs above.${RESET_FORMAT}"
fi


echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
