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

# Function to display messages with formatting
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${BOLD_TEXT}${message}${RESET_FORMAT}"
}

# Function to check command success
check_command() {
    if [ $? -eq 0 ]; then
        print_message "$GREEN_TEXT" "✓ Success: $1"
    else
        print_message "$RED_TEXT" "✗ Error: $1"
        print_message "$YELLOW_TEXT" "Troubleshooting: $2"
        
    fi
}

# Function to wait for user to proceed - for manual verification steps
wait_for_user() {
    print_message "$CYAN_TEXT" "Press Enter when you're ready to continue..."
    read
}

# Check for required tools
print_message "$CYAN_TEXT" "Checking for required tools..."
for tool in git gcloud terraform kubectl jq; do
    if ! command -v $tool &> /dev/null; then
        print_message "$RED_TEXT" "Error: $tool is not installed or not in PATH"
        
    fi
done

echo
# Get GCP region
echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -p "Region: " GCP_REGION
GCP_REGION=${GCP_REGION:-us-central1}

# Task 1: Use Terraform to provision infrastructure
task1() {
    print_message "$MAGENTA_TEXT" "TASK 1: Provisioning infrastructure with Terraform"
    
    # Clone the repository
    print_message "$CYAN_TEXT" "Cloning the GitHub repository..."
    git clone https://github.com/Redislabs-Solution-Architects/gcp-microservices-demo-qwiklabs.git
    check_command "Repository cloned" "Check your internet connection or GitHub access"
    
    # Navigate to the repository directory
    pushd gcp-microservices-demo-qwiklabs
    
    # Create terraform.tfvars file
    print_message "$CYAN_TEXT" "Creating terraform.tfvars file..."
    cat <<EOF > terraform.tfvars
gcp_project_id = "$(gcloud config list project --format='value(core.project)')"
gcp_region = "${GCP_REGION}"
EOF
    check_command "terraform.tfvars created" "Verify gcloud is configured properly"
    
    # Initialize Terraform
    print_message "$CYAN_TEXT" "Initializing Terraform..."
    terraform init
    check_command "Terraform initialized" "Check Terraform installation or internet connection"
    
    # Deploy the stack
    print_message "$CYAN_TEXT" "Deploying the stack with Terraform (this may take 5-10 minutes)..."
    print_message "$YELLOW_TEXT" "Please be patient while the resources are being provisioned..."
    echo
    echo "${RED_TEXT}${BOLD_TEXT}Till then, consider Subscribing my channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT} https://www.youtube.com/@Arcade61432 ${RESET_FORMAT}"
    echo
    terraform apply -auto-approve
    check_command "Terraform apply completed" "Check the Terraform logs for specific errors"
    
    # Store Redis Enterprise database information in environment variables
    print_message "$CYAN_TEXT" "Storing Redis Enterprise database information in environment variables..."
    export REDIS_DEST=$(terraform output db_private_endpoint | tr -d '"')
    export REDIS_DEST_PASS=$(terraform output db_password | tr -d '"')
    export REDIS_ENDPOINT="${REDIS_DEST},user=default,password=${REDIS_DEST_PASS}"
    check_command "Environment variables set" "Check if Terraform outputs are available"
    
    # Target environment to the GKE cluster
    print_message "$CYAN_TEXT" "Targeting environment to the GKE cluster..."
    gcloud container clusters get-credentials \
    $(terraform output -raw gke_cluster_name) \
    --region $(terraform output -raw region)
    check_command "Environment targeted to GKE cluster" "Verify GKE cluster was created successfully"
    
    # Get the External-IP for the web application
    print_message "$CYAN_TEXT" "Getting the External-IP for the web application..."
    print_message "$YELLOW_TEXT" "Waiting for the external IP to be assigned (this may take a moment)..."
    
    # Wait for the service to get an external IP
    external_ip=""
    attempt=0
    max_attempts=30
    
    while [ -z "$external_ip" ] && [ $attempt -lt $max_attempts ]; do
        external_ip=$(kubectl get service frontend-external -n redis -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -z "$external_ip" ]; then
            sleep 10
            ((attempt++))
            print_message "$YELLOW_TEXT" "Waiting for external IP assignment... Attempt $attempt/$max_attempts"
        fi
    done
    
    if [ -z "$external_ip" ]; then
        print_message "$RED_TEXT" "Failed to get external IP after multiple attempts."
        print_message "$YELLOW_TEXT" "Run this command manually to check: kubectl get service frontend-external -n redis"
    else
        print_message "$GREEN_TEXT" "External IP obtained: $external_ip"
        print_message "$GREEN_TEXT" "Access the eCommerce website at: http://$external_ip"
    fi
    
    # Manual step for the user
    print_message "$YELLOW_TEXT" "${BOLD_TEXT}MANUAL ACTION REQUIRED:${RESET_FORMAT}"
    print_message "$YELLOW_TEXT" "1. Open http://$external_ip in your browser"
    print_message "$YELLOW_TEXT" "2. Add some items to your shopping cart to test data migration later"
    wait_for_user
}

# Task 2: Migrate the shopping cart data from OSS Redis to Redis Enterprise
task2() {
    print_message "$MAGENTA_TEXT" "TASK 2: Migrating shopping cart data from OSS Redis to Redis Enterprise"
    
    # Set the Kubernetes namespace to redis
    print_message "$CYAN_TEXT" "Setting Kubernetes namespace to redis..."
    kubectl config set-context --current --namespace=redis
    check_command "Namespace set to redis" "Check if the redis namespace exists"
    
    # Show the current pointer for the cartservice
    print_message "$CYAN_TEXT" "Showing current pointer for the cartservice (pointing to OSS Redis)..."
    kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
    
    # Create a Kubernetes secret for Redis Enterprise database connection
    print_message "$CYAN_TEXT" "Creating Kubernetes secret for Redis Enterprise database connection..."
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: redis-creds
type: Opaque
stringData:
  REDIS_SOURCE: redis://redis-cart:6379
  REDIS_DEST: redis://${REDIS_DEST}
  REDIS_DEST_PASS: ${REDIS_DEST_PASS}
EOF
    check_command "Kubernetes secret created" "Check if the secret already exists or if there are permission issues"
    
    # Run a Kubernetes job to migrate data
    print_message "$CYAN_TEXT" "Running a Kubernetes job to migrate data from OSS Redis to Redis Enterprise..."
    print_message "$YELLOW_TEXT" "This process should take about 15 seconds..."
    kubectl apply -f https://raw.githubusercontent.com/Redislabs-Solution-Architects/gcp-microservices-demo-qwiklabs/main/util/redis-migrator-job.yaml
    check_command "Migration job started" "Check if the job manifest is accessible"
    
    # Wait for the migration job to complete
    print_message "$CYAN_TEXT" "Waiting for migration job to complete..."
    kubectl wait --for=condition=complete --timeout=120s job/redis-migrator
    check_command "Migration job completed" "Check the job logs for details: kubectl logs job/redis-migrator"
    
    # Show the current pointer for the cartservice again
    print_message "$CYAN_TEXT" "Showing current pointer for the cartservice (still pointing to OSS Redis)..."
    kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
    
    # Apply patch command to update the cartservice deployment
    print_message "$CYAN_TEXT" "Applying patch to update cartservice to point to Redis Enterprise..."
    print_message "$YELLOW_TEXT" "This process should take about 30 seconds..."
    kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"'$REDIS_ENDPOINT'"}]}]}}}}'
    check_command "Cartservice patched" "Check if the deployment exists and if you have permission to patch it"
    
    # Wait for the deployment to stabilize
    print_message "$CYAN_TEXT" "Waiting for deployment to stabilize..."
    kubectl rollout status deployment/cartservice --timeout=60s
    check_command "Deployment stabilized" "Check the deployment status manually: kubectl rollout status deployment/cartservice"
    
    # Show the new pointer for the cartservice
    print_message "$CYAN_TEXT" "Showing new pointer for the cartservice (now pointing to Redis Enterprise)..."
    kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
    
    # Manual step for the user
    print_message "$YELLOW_TEXT" "${BOLD_TEXT}MANUAL ACTION REQUIRED:${RESET_FORMAT}"
    print_message "$YELLOW_TEXT" "1. Refresh your browser and verify that the same items remain in the shopping cart"
    print_message "$YELLOW_TEXT" "2. Add a few more items to verify the application is now using Redis Enterprise"
    wait_for_user
}

# Task 3: Roll back to the OSS Redis
task3() {
    print_message "$MAGENTA_TEXT" "TASK 3: Rolling back to OSS Redis"
    
    # Run patch command to use OSS Redis again
    print_message "$CYAN_TEXT" "Applying patch to point cartservice back to OSS Redis..."
    print_message "$YELLOW_TEXT" "This process should take about 30 seconds..."
    kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"redis-cart:6379"}]}]}}}}'
    check_command "Cartservice patched to use OSS Redis" "Check if the deployment exists and if you have permission to patch it"
    
    # Wait for the deployment to stabilize
    print_message "$CYAN_TEXT" "Waiting for deployment to stabilize..."
    kubectl rollout status deployment/cartservice --timeout=60s
    check_command "Deployment stabilized" "Check the deployment status manually: kubectl rollout status deployment/cartservice"
    
    # Verify the service has been pointed to OSS Redis
    print_message "$CYAN_TEXT" "Verifying service is pointed to OSS Redis..."
    kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
    
    # Manual step for the user
    print_message "$YELLOW_TEXT" "${BOLD_TEXT}MANUAL ACTION REQUIRED:${RESET_FORMAT}"
    print_message "$YELLOW_TEXT" "1. Refresh your browser and access the shopping cart content"
    print_message "$YELLOW_TEXT" "2. You should NOT see the items added when Redis Enterprise was backing the cart"
    print_message "$YELLOW_TEXT" "3. This verifies that the service is now using OSS Redis"
    wait_for_user
}

# Task 4: Patch the Cart deployment to point to Redis Enterprise Database again
task4() {
    print_message "$MAGENTA_TEXT" "TASK 4: Patching the Cart deployment to use Redis Enterprise Database again"
    
    # Run patch command to point to Redis Enterprise again
    print_message "$CYAN_TEXT" "Applying patch to point cartservice to Redis Enterprise again..."
    print_message "$YELLOW_TEXT" "This process should take about 30 seconds..."
    kubectl patch deployment cartservice --patch '{"spec":{"template":{"spec":{"containers":[{"name":"server","env":[{"name":"REDIS_ADDR","value":"'$REDIS_ENDPOINT'"}]}]}}}}'
    check_command "Cartservice patched to use Redis Enterprise" "Check if the deployment exists and if you have permission to patch it"
    
    # Wait for the deployment to stabilize
    print_message "$CYAN_TEXT" "Waiting for deployment to stabilize..."
    kubectl rollout status deployment/cartservice --timeout=60s
    check_command "Deployment stabilized" "Check the deployment status manually: kubectl rollout status deployment/cartservice"
    
    # Verify service is pointed to Redis Enterprise
    print_message "$CYAN_TEXT" "Verifying service is pointed to Redis Enterprise..."
    kubectl get deployment cartservice -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
    
    # Manual step for the user
    print_message "$YELLOW_TEXT" "${BOLD_TEXT}MANUAL ACTION REQUIRED:${RESET_FORMAT}"
    print_message "$YELLOW_TEXT" "1. Refresh your browser and access the shopping cart content"
    print_message "$YELLOW_TEXT" "2. You should see the items which were added earlier when using Redis Enterprise"
    wait_for_user
    
    # Delete the OSS Redis deployment
    print_message "$CYAN_TEXT" "Deleting the OSS Redis deployment..."
    kubectl delete deploy redis-cart
    check_command "OSS Redis deployment deleted" "Check if the deployment exists"
}

# Main execution
main() {
    print_message "$CYAN_TEXT" "Checking Google Cloud login status..."
    gcloud auth list > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_message "$RED_TEXT" "You must be logged into Google Cloud to proceed."
        print_message "$YELLOW_TEXT" "Run 'gcloud auth login' and try again."
    fi
        
    # Execute each task
    task1
    task2
    task3
    task4
    
    popd > /dev/null 2>&1 # Return to original directory
}

# Run the main function
main

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo