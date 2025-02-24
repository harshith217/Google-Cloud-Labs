#!/bin/bash

# Foreground Colors
BLACK_TEXT=$'\033[0;30m'
RED_TEXT=$'\033[0;31m'
GREEN_TEXT=$'\033[0;32m'
YELLOW_TEXT=$'\033[0;33m'
BLUE_TEXT=$'\033[0;34m'
MAGENTA_TEXT=$'\033[0;35m'
CYAN_TEXT=$'\033[0;36m'
WHITE_TEXT=$'\033[0;37m'

# Background Colors
BLACK_BG=$'\033[0;40m'
RED_BG=$'\033[0;41m'
GREEN_BG=$'\033[0;42m'
YELLOW_BG=$'\033[0;43m'
BLUE_BG=$'\033[0;44m'
MAGENTA_BG=$'\033[0;45m'
CYAN_BG=$'\033[0;46m'
WHITE_BG=$'\033[0;47m'

# Bright Foreground Colors
BRIGHT_BLACK_TEXT=$'\033[0;90m'
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'

# Bright Background Colors
BRIGHT_BLACK_BG=$'\033[0;100m'
BRIGHT_RED_BG=$'\033[0;101m'
BRIGHT_GREEN_BG=$'\033[0;102m'
BRIGHT_YELLOW_BG=$'\033[0;103m'
BRIGHT_BLUE_BG=$'\033[0;104m'
BRIGHT_MAGENTA_BG=$'\033[0;105m'
BRIGHT_CYAN_BG=$'\033[0;106m'
BRIGHT_WHITE_BG=$'\033[0;107m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

# Start of the script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Prompt user for input
echo "${YELLOW_TEXT}${BOLD_TEXT}Please Enter ZONE:${RESET_FORMAT}"
read -p "${GREEN_TEXT}Zone: ${RESET_FORMAT}" ZONE

# Set the zone
echo "${CYAN_TEXT}${BOLD_TEXT}Setting the zone to ${ZONE}...${RESET_FORMAT}"
export ZONE=$ZONE
gcloud config set compute/zone $ZONE

# Create a GKE cluster
echo "${CYAN_TEXT}${BOLD_TEXT}Creating a GKE cluster named 'lab-cluster'...${RESET_FORMAT}"
gcloud container clusters create --machine-type=e2-medium --zone=$ZONE lab-cluster

# Get cluster credentials
echo "${CYAN_TEXT}${BOLD_TEXT}Fetching credentials for the cluster...${RESET_FORMAT}"
gcloud container clusters get-credentials lab-cluster

# Deploy a sample application
echo "${CYAN_TEXT}${BOLD_TEXT}Deploying the 'hello-server' application...${RESET_FORMAT}"
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

# Expose the application
echo "${CYAN_TEXT}${BOLD_TEXT}Exposing the 'hello-server' application on port 8080...${RESET_FORMAT}"
kubectl expose deployment hello-server --type=LoadBalancer --port 8080

echo "${CYAN_TEXT}${BOLD_TEXT}Waiting for the service to be ready (70 seconds)...${RESET_FORMAT}"
sleep 70

# Prompt user to confirm progress
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Have you checked the progress till Task 4?${RESET_FORMAT}"
read -p "${GREEN_TEXT}Type Y/Yes to continue or N/No to exit: ${RESET_FORMAT}" USER_CONFIRMATION

# Convert user input to lowercase for case-insensitive comparison
USER_CONFIRMATION=$(echo "$USER_CONFIRMATION" | tr '[:upper:]' '[:lower:]')

# Check user input
if [[ "$USER_CONFIRMATION" == "y" || "$USER_CONFIRMATION" == "yes" ]]; then
    echo "${CYAN_TEXT}${BOLD_TEXT}Continuing with the process...${RESET_FORMAT}"
elif [[ "$USER_CONFIRMATION" == "n" || "$USER_CONFIRMATION" == "no" ]]; then
    echo "${RED_TEXT}${BOLD_TEXT}Please check the progress till Task 4.${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}Invalid input. Please enter Y/Yes or N/No.${RESET_FORMAT}"
fi

# Delete the cluster
echo "${RED_TEXT}${BOLD_TEXT}Deleting the 'lab-cluster'...${RESET_FORMAT}"
gcloud container clusters delete lab-cluster

echo "${RED_TEXT}${BOLD_TEXT}Cluster Deleted!${RESET_FORMAT}"
echo
# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo