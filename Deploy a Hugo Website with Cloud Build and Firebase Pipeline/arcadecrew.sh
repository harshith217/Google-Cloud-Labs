#!/bin/bash

# Color and Formatting Definitions
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

# --- Helper Functions ---
# Function to wait for user confirmation after manual steps
function wait_for_confirmation {
    local prompt_message="$1"
    while true; do
        echo
        echo -n "${YELLOW_TEXT}${BOLD_TEXT}${prompt_message} (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${GREEN_TEXT}${BOLD_TEXT}Proceeding...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED_TEXT}${BOLD_TEXT}Please complete the required manual step and then press Y to continue.${RESET_FORMAT}"
        else
            echo
            echo "${MAGENTA_TEXT}${BOLD_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

# --- Script Execution ---
clear

echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Step 1: Displaying the contents of installhugo.sh file.${RESET_FORMAT}"
cat /tmp/installhugo.sh
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 2: Moving to the home directory and executing installhugo.sh.${RESET_FORMAT}"
cd ~
/tmp/installhugo.sh
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Setting up project environment variables.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "PROJECT_ID set to: $PROJECT_ID"
echo "PROJECT_NUMBER set to: $PROJECT_NUMBER"
echo "REGION set to: $REGION"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 4: Updating system and installing required packages.${RESET_FORMAT}"
sudo apt-get update -y # Added -y for non-interactive install
sudo apt-get install -y git # Added -y
sudo apt-get install -y gh # Added -y
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Step 5: Installing latest GitHub CLI using webi.sh (may already be installed).${RESET_FORMAT}"
curl -sS https://webi.sh/gh | sh
# Add gh to path if installed via webi - adjust path if needed
export PATH=$HOME/.local/bin:$PATH
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 6: Authenticating GitHub CLI.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Please follow the prompts to authenticate GitHub CLI with your browser or a token.${RESET_FORMAT}"
gh auth login
echo # Add a newline for better spacing after auth prompts
GITHUB_LOGIN_CHECK=$(gh api user -q ".login" || echo "ERROR")
if [[ "$GITHUB_LOGIN_CHECK" == "ERROR" || -z "$GITHUB_LOGIN_CHECK" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Error: GitHub CLI authentication failed. Please check credentials and try again.${RESET_FORMAT}"
fi
echo "${GREEN_TEXT}GitHub CLI authenticated as: ${GITHUB_LOGIN_CHECK}${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Step 7: Configuring GitHub user details.${RESET_FORMAT}"
GITHUB_USERNAME=$(gh api user -q ".login")
# Ensure USER_EMAIL is set - prompt if necessary
if [[ -z "${USER_EMAIL}" ]]; then
    echo -n "${YELLOW_TEXT}Please enter the email address associated with your GitHub account: ${RESET_FORMAT}"
    read USER_EMAIL
fi
git config --global user.name "${GITHUB_USERNAME}"
git config --global user.email "${USER_EMAIL}"
echo "Git user.name configured as: ${GITHUB_USERNAME}"
echo "Git user.email configured as: ${USER_EMAIL}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 8: Creating and cloning the Hugo site repository.${RESET_FORMAT}"
cd ~
# Check if repo exists locally first
if [ -d "my_hugo_site" ]; then
    echo "${YELLOW_TEXT}Directory 'my_hugo_site' already exists. Skipping repo creation and clone.${RESET_FORMAT}"
    cd my_hugo_site
else
    echo "Creating private GitHub repo 'my_hugo_site'..."
    gh repo create my_hugo_site --private --source=. --push # Create and push initial empty commit
    REPO_CREATE_STATUS=$?
    if [ $REPO_CREATE_STATUS -ne 0 ]; then
        echo "${RED_TEXT}${BOLD_TEXT}Error creating GitHub repository. It might already exist on GitHub. Attempting to clone...${RESET_FORMAT}"
    fi
    echo "Cloning repository 'my_hugo_site'..."
    gh repo clone "${GITHUB_USERNAME}/my_hugo_site"
    CLONE_STATUS=$?
     if [ $CLONE_STATUS -ne 0 ]; then
        echo "${RED_TEXT}${BOLD_TEXT}Error cloning GitHub repository. Please check permissions and if it exists.${RESET_FORMAT}"
    fi
    cd my_hugo_site
fi
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 9: Initializing the Hugo site.${RESET_FORMAT}"
# We are already inside the cloned directory if successful
echo "Initializing Hugo site inside 'my_hugo_site' directory..."
/tmp/hugo new site . --force # Use '.' because we are already inside
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 10: Adding the Hugo theme.${RESET_FORMAT}"
cd ~/my_hugo_site # Ensure we are in the correct directory

# Clone the theme only if the directory doesn't exist
if [ ! -d "themes/hello-friend-ng" ]; then
    echo "Cloning theme 'hello-friend-ng'..."
    git clone \
        https://github.com/rhazdon/hugo-theme-hello-friend-ng.git themes/hello-friend-ng
else
    echo "Theme directory 'themes/hello-friend-ng' already exists. Skipping clone."
fi

echo "Ensuring correct theme is set in config.toml..."
# Check if config.toml exists, create a basic one if not (though hugo new site should create it)
if [ ! -f "config.toml" ]; then
    echo "baseURL = 'http://example.org/'" > config.toml
    echo "languageCode = 'en-us'" >> config.toml
    echo "title = 'My New Hugo Site'" >> config.toml
fi

# Remove any existing theme line (commented or uncommented) to prevent duplicates
sed -i.bak '/^theme\s*=/d' config.toml

# Add the correct theme line at the end
echo 'theme = "hello-friend-ng"' >> config.toml

# Verify the change
echo "--- config.toml theme line ---"
grep '^theme\s*=' config.toml
echo "----------------------------"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Step 11: Removing unnecessary Git files from the theme.${RESET_FORMAT}"
if [ -d "themes/hello-friend-ng/.git" ]; then
    echo "Removing .git directory from theme..."
    sudo rm -rf themes/hello-friend-ng/.git # Use -f to avoid prompts if missing
fi
if [ -f "themes/hello-friend-ng/.gitignore" ]; then
    echo "Removing .gitignore file from theme..."
    sudo rm -f themes/hello-friend-ng/.gitignore # Use -f
fi
echo

# --- Manual Check Point for Task 1 ---
echo "${RED_TEXT}${BOLD_TEXT}Step 12: Manual Check - Starting Hugo Server.${RESET_FORMAT}"
echo "${YELLOW_TEXT}The Hugo server will now start in the FOREGROUND."
echo "1. Wait for the 'Web Server is available at...' message."
echo "2. Open your web browser and navigate to: ${BOLD_TEXT}http://<YOUR_VM_EXTERNAL_IP>:8080${RESET_FORMAT}"
echo "${YELLOW_TEXT}   (Replace <YOUR_VM_EXTERNAL_IP> with the External IP address of this VM)."
echo "3. Verify the 'My New Hugo Site' page loads correctly."
echo "4. ${BOLD_TEXT}Return to this terminal and press CTRL+C to stop the server.${RESET_FORMAT}"
echo "${YELLOW_TEXT}The script will pause until you stop the server.${RESET_FORMAT}"
echo # Add newline for clarity
# Run Hugo server in the foreground
cd ~/my_hugo_site # Ensure we are in the correct directory
/tmp/hugo server -D --bind 0.0.0.0 --port 8080
# Script execution resumes here AFTER user presses CTRL+C

echo "${GREEN_TEXT}Hugo server stopped by user.${RESET_FORMAT}"

wait_for_confirmation "Have you successfully viewed the site at http://<EXTERNAL_IP>:8080 and stopped the server with CTRL+C?"

# --- Resume Automation ---

echo "${GREEN_TEXT}${BOLD_TEXT}Step 13: Installing Firebase CLI.${RESET_FORMAT}"
# Check if firebase command exists
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI not found. Installing..."
    curl -sL https://firebase.tools | bash
else
    echo "Firebase CLI already installed."
fi
# Add firebase to path if installed now (common location)
export PATH=$HOME/.local/bin:$PATH
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 14: Initializing the Firebase project (Manual Interaction Required).${RESET_FORMAT}"
echo "${RED_TEXT}${BOLD_TEXT}ACTION REQUIRED:${RESET_FORMAT}"
echo "${YELLOW_TEXT}The next command 'firebase init' requires manual input."
echo "Please follow these steps carefully in the terminal:"
echo " 1. When prompted, select: ${BOLD_TEXT}Hosting: Configure files for Firebase Hosting...${RESET_FORMAT}${YELLOW_TEXT} (use arrow keys and spacebar, then Enter)"
echo " 2. Select: ${BOLD_TEXT}Use an existing project${RESET_FORMAT}"
echo " 3. Select your project ID: ${BOLD_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo " 4. Public directory: Press Enter to accept the default (${BOLD_TEXT}public${RESET_FORMAT}${YELLOW_TEXT})"
echo " 5. Configure as a single-page app: Enter ${BOLD_TEXT}N${RESET_FORMAT}${YELLOW_TEXT} (No)"
echo " 6. Set up automatic builds with GitHub: Enter ${BOLD_TEXT}N${RESET_FORMAT}${YELLOW_TEXT} (No)"
echo " 7. If asked to overwrite files (like public/index.html), enter ${BOLD_TEXT}Y${RESET_FORMAT}${YELLOW_TEXT} (Yes)"
echo
echo "${YELLOW_TEXT}Now running 'firebase init'. Please follow the prompts as described above.${RESET_FORMAT}"
cd ~/my_hugo_site # Ensure we are in the correct directory
firebase init

wait_for_confirmation "Have you completed the 'firebase init' steps as described above?"

echo "${BLUE_TEXT}${BOLD_TEXT}Step 15: Building with Hugo and Deploying the site to Firebase.${RESET_FORMAT}"
cd ~/my_hugo_site # Ensure we are in the correct directory
echo "Running Hugo build..."
/tmp/hugo
echo "Deploying to Firebase..."
firebase deploy --only hosting # Removed the && as hugo build might output non-error messages
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 16: Configuring Git user details specifically for build commits (optional but good practice).${RESET_FORMAT}"
# These might be overridden by subsequent steps or Cloud Build context, but set them for clarity
git config --global user.name "Automated Build" # Changed from "hugo"
git config --global user.email "build@example.com" # Changed from "hugo@blogger.com"
echo "Git user configured for potential build commits."
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Step 17: Staging initial site files, ignoring 'resources', and pushing to GitHub.${RESET_FORMAT}"
cd ~/my_hugo_site
# Ensure .gitignore exists and add 'resources' if not already present
touch .gitignore
if ! grep -q "^resources/?$" .gitignore; then
    echo "Adding 'resources' directory to .gitignore..."
    echo "resources" >> .gitignore
fi
# Add 'public' directory (generated by hugo/firebase) if not already present
if ! grep -q "^public/?$" .gitignore; then
    echo "Adding 'public' directory to .gitignore..."
    echo "public" >> .gitignore
fi
# Add firebase specific files if not already present
if ! grep -q "^firebase.json$" .gitignore; then echo "firebase.json" >> .gitignore; fi
if ! grep -q "^\.firebaserc$" .gitignore; then echo ".firebaserc" >> .gitignore; fi
if ! grep -q "^database.rules.json$" .gitignore; then echo "database.rules.json" >> .gitignore; fi


echo "Adding all files to Git..."
git add .
echo "Committing initial site structure..."
# Check if there are changes to commit
if git diff-index --quiet HEAD --; then
    echo "No changes to commit."
else
    git commit -m "Initial Hugo site setup and Firebase config"
    echo "Pushing changes to GitHub master branch..."
    git push -u origin master
fi
echo

echo "${RED_TEXT}${BOLD_TEXT}Step 18: Copying cloudbuild.yaml and displaying its content.${RESET_FORMAT}"
cd ~/my_hugo_site
if [ -f "/tmp/cloudbuild.yaml" ]; then
    cp /tmp/cloudbuild.yaml .
    echo "cloudbuild.yaml copied."
    echo "--- Contents of cloudbuild.yaml ---"
    cat cloudbuild.yaml
    echo "-----------------------------------"
else
    echo "${RED_TEXT}Error: /tmp/cloudbuild.yaml not found. Cannot proceed with Cloud Build setup.${RESET_FORMAT}"
    # exit 1 # Decide if you want to stop the script here
fi
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Step 19: Creating a Cloud Build GitHub connection.${RESET_FORMAT}"
# Check if connection already exists
EXISTING_CONNECTION=$(gcloud builds connections list --region=$REGION --filter="name:cloud-build-connection" --format="value(name)")
if [[ -z "$EXISTING_CONNECTION" ]]; then
    echo "Creating Cloud Build connection 'cloud-build-connection'..."
    gcloud builds connections create github cloud-build-connection --project=$PROJECT_ID --region=$REGION
else
    echo "Cloud Build connection 'cloud-build-connection' already exists."
fi
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 20: Verifying the Cloud Build GitHub Connection.${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}ACTION REQUIRED:${RESET_FORMAT}"
echo "${YELLOW_TEXT}1. Open the following URL in your browser:"
echo "${BOLD_TEXT}https://console.cloud.google.com/cloud-build/repositories/connect?project=$PROJECT_ID${RESET_FORMAT}"
echo "${YELLOW_TEXT}2. Find the 'cloud-build-connection' you just created (or that existed)."
echo "3. If it shows 'Pending authentication' or similar, click 'CONTINUE AUTHENTICATION' or follow the link provided by the 'gcloud builds connections describe' command (run manually if needed)."
echo "4. Follow the prompts in the GitHub pop-up window to authorize the Google Cloud Build app."
echo "5. Grant access ONLY to the '${BOLD_TEXT}my_hugo_site${RESET_FORMAT}${YELLOW_TEXT}' repository."
echo "6. Once authorized, the connection status in the Google Cloud Console should update."
echo

# Renamed the second check_progress function for clarity
function check_github_app_progress {
    while true; do
        echo
        echo -n "${YELLOW_TEXT}${BOLD_TEXT}Have you authorized the Cloud Build GitHub App for the 'my_hugo_site' repository? (Y/N): ${RESET_FORMAT}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${GREEN_TEXT}${BOLD_TEXT}Proceeding...${RESET_FORMAT}"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${RED_TEXT}${BOLD_TEXT}Please authorize the Cloud Build GitHub App via the Google Cloud Console link provided above, then press Y to continue.${RESET_FORMAT}"
        else
            echo
            echo "${MAGENTA_TEXT}${BOLD_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
        fi
    done
}

check_github_app_progress # Call the renamed function

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 21: Describing the Cloud Build connection (check status).${RESET_FORMAT}"
gcloud builds connections describe cloud-build-connection --region=$REGION --project=$PROJECT_ID
echo "${MAGENTA_TEXT}Check the output above. Ensure 'installationState.stage' is NOT 'PENDING_USER_OAUTH'.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 22: Connecting the specific GitHub repository to Cloud Build.${RESET_FORMAT}"
# Check if repository connection already exists
EXISTING_REPO_CONN=$(gcloud builds repositories list --connection=cloud-build-connection --region=$REGION --project=$PROJECT_ID --filter="remoteUri:https://github.com/${GITHUB_USERNAME}/my_hugo_site.git" --format="value(name)")
if [[ -z "$EXISTING_REPO_CONN" ]]; then
    echo "Connecting repository 'hugo-website-build-repository'..."
    gcloud builds repositories create hugo-website-build-repository \
        --remote-uri="https://github.com/${GITHUB_USERNAME}/my_hugo_site.git" \
        --connection="cloud-build-connection" --region=$REGION --project=$PROJECT_ID
else
    echo "Cloud Build repository connection 'hugo-website-build-repository' already exists."
fi
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Step 23: Creating a Cloud Build trigger.${RESET_FORMAT}"
# Check if trigger already exists
EXISTING_TRIGGER=$(gcloud builds triggers list --region=$REGION --project=$PROJECT_ID --filter="name:commit-to-master-branch1" --format="value(name)")
if [[ -z "$EXISTING_TRIGGER" ]]; then
    echo "Creating trigger 'commit-to-master-branch1'..."
    gcloud builds triggers create github --name="commit-to-master-branch1" \
         --repository=projects/$PROJECT_ID/locations/$REGION/connections/cloud-build-connection/repositories/hugo-website-build-repository \
         --build-config='cloudbuild.yaml' \
         --service-account="projects/$PROJECT_ID/serviceAccounts/$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
         --region=$REGION \
         --branch-pattern='^master$' \
         --project=$PROJECT_ID
else
    echo "Cloud Build trigger 'commit-to-master-branch1' already exists."
fi
# Grant Firebase Admin role to the default Cloud Build service account if not already granted (Best Practice)
# Note: The lab uses the Compute Engine SA, which might already have broad permissions, but explicitly granting to the CB SA is better.
CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
echo "Ensuring Cloud Build Service Account (${CB_SA}) has Firebase Hosting Admin role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CB_SA}" \
    --role="roles/firebasehosting.admin" --condition=None > /dev/null # Suppress noisy output

echo

echo "${RED_TEXT}${BOLD_TEXT}Step 24: Updating the site title in config.toml.${RESET_FORMAT}"
cd ~/my_hugo_site
# Use a more robust sed command to avoid issues if title line format varies slightly
sed -i.bak "s/^title\s*=.*/title = 'Blogging with Hugo and Cloud Build'/" config.toml
echo "Site title updated in config.toml."
# Display the change
echo "--- Updated config.toml ---"
grep "^title =" config.toml
echo "---------------------------"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Step 25: Adding, committing, and pushing title change to trigger Cloud Build.${RESET_FORMAT}"
cd ~/my_hugo_site
git add config.toml cloudbuild.yaml .gitignore # Be specific about changed files
echo "Committing changes..."
git commit -m "Update site title and add cloudbuild.yaml"
echo "Pushing changes to GitHub to trigger build..."
git push -u origin master
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}Step 26: Waiting and listing Cloud Build history.${RESET_FORMAT}"
echo "Waiting for 20 seconds for the build to start..."
sleep 20
gcloud builds list --region=$REGION --project=$PROJECT_ID --limit=5 # Show recent builds
echo

echo "${BLUE_TEXT}${BOLD_TEXT}Step 27: Fetching logs for the latest build triggered by the last commit.${RESET_FORMAT}"
LAST_COMMIT_HASH=$(git rev-parse HEAD)
echo "Fetching logs for commit: $LAST_COMMIT_HASH"
# Wait a bit longer for the build to potentially finish or generate significant logs
echo "Waiting another 30 seconds for build progress..."
sleep 30
LATEST_BUILD_ID=$(gcloud builds list --region=$REGION --project=$PROJECT_ID --filter="sourceProvenance.resolvedRepoSource.commitSha='${LAST_COMMIT_HASH}'" --format='value(id)' --limit=1)

if [[ -n "$LATEST_BUILD_ID" ]]; then
    echo "Fetching logs for Build ID: $LATEST_BUILD_ID"
    gcloud builds log --region=$REGION "$LATEST_BUILD_ID" --project=$PROJECT_ID
else
    echo "${RED_TEXT}Could not find a recent build for commit ${LAST_COMMIT_HASH}. Please check the Cloud Build history in the console.${RESET_FORMAT}"
    # Try fetching the absolute latest build log as a fallback
    LATEST_BUILD_ID_FALLBACK=$(gcloud builds list --region=$REGION --project=$PROJECT_ID --format='value(id)' --limit=1)
     if [[ -n "$LATEST_BUILD_ID_FALLBACK" ]]; then
        echo "${YELLOW_TEXT}Fetching logs for the absolute latest build (ID: $LATEST_BUILD_ID_FALLBACK) as a fallback...${RESET_FORMAT}"
        gcloud builds log --region=$REGION "$LATEST_BUILD_ID_FALLBACK" --project=$PROJECT_ID
    fi
fi
echo

# Step 28 (Sleep) is integrated into Step 27 wait times

echo "${CYAN_TEXT}${BOLD_TEXT}Step 29: Extracting the Hosting URL from Cloud Build logs (if successful).${RESET_FORMAT}"
if [[ -n "$LATEST_BUILD_ID" ]]; then
    echo "Searching logs of build $LATEST_BUILD_ID for Hosting URL..."
    HOSTING_URL=$(gcloud builds log --region=$REGION "$LATEST_BUILD_ID" --project=$PROJECT_ID | grep "Hosting URL")
    if [[ -n "$HOSTING_URL" ]]; then
        echo "${GREEN_TEXT}${BOLD_TEXT}${HOSTING_URL}${RESET_FORMAT}"
    else
        echo "${YELLOW_TEXT}Hosting URL not found in the logs for build $LATEST_BUILD_ID. The build might have failed or not completed deployment.${RESET_FORMAT}"
        echo "${YELLOW_TEXT}You can check the Firebase Hosting console: https://console.firebase.google.com/project/${PROJECT_ID}/hosting/main${RESET_FORMAT}"
    fi
else
     echo "${RED_TEXT}Cannot extract Hosting URL as the specific build ID was not found.${RESET_FORMAT}"
fi
echo

echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}      SCRIPT EXECUTION FINISHED (Check Status)         ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Please verify the final deployment using the Hosting URL printed above or by checking the Firebase/Cloud Build consoles.${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
