# Define color codes
YELLOW='\033[0;33m'
BG_RED=`tput setab 1`
TEXT_GREEN=`tput setab 2`
TEXT_RED=`tput setaf 1`

BOLD=`tput bold`
RESET=`tput sgr0`

NC='\033[0m'

echo "${BG_RED}${BOLD}Starting Execution${RESET}"

echo -e "${YELLOW}${BOLD}Please enter the location (Region):${RESET}"
read LOCATION

# Enable required Google Cloud services
gcloud services enable documentai.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable geocoding-backend.googleapis.com

# Create an API key with a custom display name
gcloud alpha services api-keys create --display-name="AradeCrew-key"