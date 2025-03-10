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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Helper functions
function print_section() {
    echo -e "\n${BOLD_TEXT}${BLUE_TEXT}=== $1 ===${RESET_FORMAT}\n"
}

function print_step() {
    echo -e "${BOLD_TEXT}${CYAN_TEXT}➤ $1${RESET_FORMAT}"
}

function print_success() {
    echo -e "${BOLD_TEXT}${GREEN_TEXT}✓ $1${RESET_FORMAT}"
}

function print_error() {
    echo -e "${BOLD_TEXT}${RED_TEXT}✗ $1${RESET_FORMAT}"
}

function print_manual_step() {
    echo -e "${BOLD_TEXT}${YELLOW_TEXT}⚠ MANUAL STEP: $1${RESET_FORMAT}"
}

function print_command() {
    echo -e "${MAGENTA_TEXT}$ $1${RESET_FORMAT}"
}

function execute_command() {
    print_command "$1"
    eval "$1"
    local status=$?
    if [ $status -eq 0 ]; then
        print_success "Command executed successfully"
    else
        print_error "Command failed with exit code $status"
        exit $status
    fi
}

function verify_command_output() {
    local command=$1
    local expected=$2
    local output=$(eval "$command")
    
    if [[ "$output" == *"$expected"* ]]; then
        print_success "Verification successful: $expected found in output"
        return 0
    else
        print_error "Verification failed: Expected to find '$expected' in output"
        echo -e "${YELLOW_TEXT}Actual output:${RESET_FORMAT}\n$output"
        return 1
    fi
}

# Check if logged in to Google Cloud
print_section "Checking Google Cloud authentication"
gcloud auth list &>/dev/null
if [ $? -ne 0 ]; then
    print_error "Not authenticated to Google Cloud. Please run 'gcloud auth login' first."
    exit 1
fi

# Get project ID
PROJECT_ID=$(gcloud config get-value project -q)
print_success "Using Google Cloud project: $PROJECT_ID"

# Set default zone from user input or use a default
print_step "Setting up environment variables"
echo -e "${BOLD_TEXT}Enter ZONE:${RESET_FORMAT}"
read zone_input
my_zone=${zone_input:-"us-central1-a"}
my_cluster="standard-cluster-1"

# Export variables for use in commands
export my_zone
export my_cluster
export PROJECT_ID

print_success "Zone set to: $my_zone"
print_success "Cluster name set to: $my_cluster"

# Task 1: Using Kubernetes Engine Monitoring
print_section "Task 1: Using Kubernetes Engine Monitoring"

print_step "Configuring kubectl tab completion"
execute_command "source <(kubectl completion bash)"

print_step "Creating a VPC-native Kubernetes cluster with monitoring enabled"
execute_command "gcloud container clusters create $my_cluster \
   --num-nodes 3 --enable-ip-alias --zone $my_zone  \
   --logging=SYSTEM \
   --monitoring=SYSTEM"

print_step "Configuring access to cluster for kubectl"
execute_command "gcloud container clusters get-credentials $my_cluster --zone $my_zone"

# Deploy a sample workload to the GKE cluster
print_section "Deploying a sample workload to GKE cluster"

print_step "Cloning the lab repository"
execute_command "git clone https://github.com/GoogleCloudPlatform/training-data-analyst || true"

print_step "Creating a soft link to the working directory"
execute_command "ln -s ~/training-data-analyst/courses/ak8s/v1.1 ~/ak8s || true"

print_step "Changing to the Monitoring directory"
execute_command "cd ~/ak8s/Monitoring/"

print_step "Deploying the hello-v2 sample application"
execute_command "kubectl create -f hello-v2.yaml"

print_step "Verifying the deployment"
execute_command "kubectl get deployments"
verify_command_output "kubectl get deployments" "hello-v2"

# Deploy the GCP-GKE-Monitor-Test application
print_section "Deploying GCP-GKE-Monitor-Test application"

print_step "Changing to the load application directory"
execute_command "cd ~/ak8s/Monitoring/gcp-gke-monitor-test"

print_step "Building and pushing Docker image"
execute_command "gcloud builds submit --tag=gcr.io/$PROJECT_ID/gcp-gke-monitor-test ."

print_step "Changing back to main working directory"
execute_command "cd ~/ak8s/Monitoring"

print_step "Updating the deployment manifest with the Docker image"
execute_command "sed -i \"s/\[DOCKER-IMAGE\]/gcr\.io\/${PROJECT_ID}\/gcp-gke-monitor-test\:latest/\" gcp-gke-monitor-test.yaml"

print_step "Deploying the GCP-GKE-Monitor-Test application"
execute_command "kubectl create -f gcp-gke-monitor-test.yaml"

print_step "Verifying the deployment"
execute_command "kubectl get deployments"
verify_command_output "kubectl get deployments" "gcp-gke-monitor-test"

print_step "Verifying the service"
execute_command "kubectl get service"
echo -e "${YELLOW_TEXT}Note: You may need to run 'kubectl get service' multiple times until the service is assigned an external IP address.${RESET_FORMAT}"

# Task 4: Creating alerts with Kubernetes Engine Monitoring
print_section "Task 4: Creating alerts with Kubernetes Engine Monitoring"

print_manual_step "Creating an Alert Policy in Google Cloud Console:"
echo -e "  ${BOLD_TEXT}1. Navigate to Monitoring > Detect > Alerting"
echo -e "  ${BOLD_TEXT}2. Click '+ Create Policy'"
echo -e "  ${BOLD_TEXT}3. Click on 'Select a metric' dropdown"
echo -e "  ${BOLD_TEXT}4. Uncheck the 'Active' option"
echo -e "  ${BOLD_TEXT}5. Type 'Kubernetes Container' in the filter"
echo -e "  ${BOLD_TEXT}6. Click on 'Kubernetes Container > Container'"
echo -e "  ${BOLD_TEXT}7. Select 'CPU request utilization'"
echo -e "  ${BOLD_TEXT}8. Click 'Apply'"
echo -e "  ${BOLD_TEXT}9. Set 'Rolling windows' to '1 min'"
echo -e "  ${BOLD_TEXT}10. Click 'Next'"
echo -e "  ${BOLD_TEXT}11. Set 'Threshold position' to 'Above Threshold'"
echo -e "  ${BOLD_TEXT}12. Set '0.99' as your 'Threshold value'"
echo -e "  ${BOLD_TEXT}13. Click 'Next'"

print_manual_step "Configure notifications and finish the alerting policy:"
echo -e "  ${BOLD_TEXT}1. Click on dropdown next to 'Notification Channels', then 'Manage Notification Channels'"
echo -e "  ${BOLD_TEXT}2. Scroll down and click 'ADD NEW' for Email"
echo -e "  ${BOLD_TEXT}3. Enter your USERNAME and display name as arcadecrew"
echo -e "  ${BOLD_TEXT}4. Click 'Save'"
echo -e "  ${BOLD_TEXT}5. Return to the previous tab"
echo -e "  ${BOLD_TEXT}6. Click 'Notification Channels' again, click refresh"
echo -e "  ${BOLD_TEXT}7. Select your display name and click 'OK'"
echo -e "  ${BOLD_TEXT}8. Name the alert 'CPU request utilization'"
echo -e "  ${BOLD_TEXT}9. Click 'Next'"
echo -e "  ${BOLD_TEXT}10. Review the alert and click 'Create Policy'"

print_success "You have successfully:"
echo -e "  ${GREEN_TEXT}✓ Created a GKE cluster with monitoring enabled"
echo -e "  ${GREEN_TEXT}✓ Deployed a sample workload to your GKE cluster"
echo -e "  ${GREEN_TEXT}✓ Deployed the GCP-GKE-Monitor-Test application"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
