#!/bin/bash

# Text formatting variables (optional, for better output)
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
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}         STARTING EXECUTION...       ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# --- Task 1: Enable APIs and set up the environment ---
echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${GREEN_TEXT}Fetching project details and setting environment variables.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

# Prompt the user for the region with color
read -p "${CYAN_TEXT}Enter the region: ${RESET_FORMAT}" REGION
export REGION # Export the variable read from the user
export ZONE="${REGION}-b" # Choose a zone within the fixed region
gcloud config set compute/zone $ZONE --quiet
gcloud config set compute/region $REGION --quiet # Also set compute/region

echo "Using Project ID: ${PROJECT_ID}"
echo "Using Project Number: ${PROJECT_NUMBER}"
echo "Using Zone: ${ZONE}"
echo "Using Region: ${REGION}"


echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${GREEN_TEXT}Enabling required GCP services.${RESET_FORMAT}"
gcloud services enable \
    cloudkms.googleapis.com \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    container.googleapis.com \
    containerregistry.googleapis.com \
    artifactregistry.googleapis.com \
    containerscanning.googleapis.com \
    ondemandscanning.googleapis.com \
    binaryauthorization.googleapis.com --quiet

echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Setting up the sample application directory and files.${RESET_FORMAT}"
# Ensure we are not already in sample-app if script is rerun
cd ~
rm -rf sample-app # Clean up previous run just in case
mkdir sample-app && cd sample-app
gcloud storage cp gs://spls/gsp521/* .

echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${GREEN_TEXT}Creating Artifact Registry repositories in ${REGION}.${RESET_FORMAT}"
# Use the corrected $REGION
gcloud artifacts repositories create artifact-scanning-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Scanning repository" --quiet || echo "${YELLOW_TEXT}Scanning repo already exists.${RESET_FORMAT}"

gcloud artifacts repositories create artifact-prod-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Production repository" --quiet || echo "${YELLOW_TEXT}Prod repo already exists.${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${GREEN_TEXT}Configuring Docker authentication for Artifact Registry in ${REGION}.${RESET_FORMAT}"
# Use the corrected $REGION
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

# --- Task 2: Create the Cloud Build pipeline (Initial) ---
echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${GREEN_TEXT}Adding initial IAM policy bindings for Cloud Build SA.${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" --condition=None --quiet

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/ondemandscanning.admin" --condition=None --quiet

echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${GREEN_TEXT}Creating the initial Cloud Build configuration file (cloudbuild.yaml).${RESET_FORMAT}"
# Use correct REGION
SCAN_IMAGE_URL_INITIAL="${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest"
cat > cloudbuild.yaml <<EOF
steps:
    # 1. Build Step.
    - id: "build"
        name: 'gcr.io/cloud-builders/docker'
        args: ['build', '-t', '${SCAN_IMAGE_URL_INITIAL}', '.']
        waitFor: ['-']

    # 2. Push to Artifact Registry (scanning repo).
    - id: "push"
        name: 'gcr.io/cloud-builders/docker'
        args: ['push', '${SCAN_IMAGE_URL_INITIAL}']
        waitFor: ['build'] # Added explicit dependency

# 8. Image built by this pipeline (implicitly refers to the one pushed)
images:
    - '${SCAN_IMAGE_URL_INITIAL}'
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} ${GREEN_TEXT}Submitting the initial Cloud Build configuration to ${REGION}.${RESET_FORMAT}"
# Use the corrected $REGION for build submission
gcloud builds submit --region=$REGION --config=cloudbuild.yaml .

# --- Task 3: Set up Binary Authorization ---
echo "${CYAN_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} ${GREEN_TEXT}Creating a vulnerability note for Container Analysis.${RESET_FORMAT}"
NOTE_ID=vulnerability_note
cat > ./vulnerability_note.json << EOM
{
    "attestation": {
        "hint": {
            "human_readable_name": "Container Vulnerabilities attestation authority"
        }
    }
}
EOM

# Create Note using curl
echo "Creating Note..."
curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./vulnerability_note.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# Verify Note Creation (Optional but good practice)
echo "Verifying Note..."
curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 10:${RESET_FORMAT} ${GREEN_TEXT}Creating a Binary Authorization attestor.${RESET_FORMAT}"
ATTESTOR_ID=vulnerability-attestor
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=${PROJECT_ID} --quiet || echo "${YELLOW_TEXT}Attestor already exists.${RESET_FORMAT}"

echo "Listing Attestors to verify creation..."
gcloud container binauthz attestors list --quiet

echo "Granting BinAuthz SA permission to view Note Occurrences..."
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
cat > ./iam_request.json << EOM
{
    "policy": {
        "bindings": [
            {
                "role": "roles/containeranalysis.notes.occurrences.viewer",
                "members": [
                    "serviceAccount:${BINAUTHZ_SA_EMAIL}"
                ]
            }
        ]
    }
}
EOM

curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 11:${RESET_FORMAT} ${GREEN_TEXT}Creating a KMS keyring and key for signing.${RESET_FORMAT}"
KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=lab-key
KEY_VERSION=1

gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}" --quiet || echo "${YELLOW_TEXT}Keyring already exists.${RESET_FORMAT}"

gcloud kms keys create "${KEY_NAME}" \
    --keyring="${KEYRING}" --location="${KEY_LOCATION}" \
    --purpose="asymmetric-signing" \
    --default-algorithm="ec-sign-p256-sha256" --quiet || echo "${YELLOW_TEXT}Key already exists.${RESET_FORMAT}"

echo "Adding KMS key public part to the Attestor..."
gcloud container binauthz attestors public-keys add \
    --attestor="${ATTESTOR_ID}" \
    --keyversion-project="${PROJECT_ID}" \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}" --quiet

echo "${CYAN_TEXT}${BOLD_TEXT}Step 12:${RESET_FORMAT} ${GREEN_TEXT}Updating the Binary Authorization policy.${RESET_FORMAT}"
cat > my_policy.yaml << EOM
defaultAdmissionRule:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: REQUIRE_ATTESTATION
    requireAttestationsBy:
        - projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}
globalPolicyEvaluationMode: ENABLE
# name: projects/${PROJECT_ID}/policy # Name field is often not needed for import
EOM

gcloud container binauthz policy import my_policy.yaml

# --- Task 4: Create a Cloud Build CI/CD pipeline with vulnerability scanning ---
echo "${CYAN_TEXT}${BOLD_TEXT}Step 13:${RESET_FORMAT} ${GREEN_TEXT}Adding required IAM roles for the enhanced pipeline.${RESET_FORMAT}"
# Grant Cloud Build SA necessary roles
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/binaryauthorization.attestorsViewer --condition=None --quiet
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/cloudkms.signerVerifier --condition=None --quiet
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/containeranalysis.notes.attacher --condition=None --quiet
# Roles from Task 2 are added again for idempotency
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" --condition=None --quiet
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/ondemandscanning.admin" --condition=None --quiet

# Grant Compute Engine Default SA kms signerVerifier role
COMPUTE_SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName='Compute Engine default service account'" --format='value(email)')
if [ -n "$COMPUTE_SA_EMAIL" ]; then
        echo "Granting Compute Engine SA ($COMPUTE_SA_EMAIL) roles/cloudkms.signerVerifier role..."
        gcloud projects add-iam-policy-binding ${PROJECT_ID} \
            --member serviceAccount:${COMPUTE_SA_EMAIL} \
            --role roles/cloudkms.signerVerifier --condition=None --quiet
else
        echo "${YELLOW_TEXT}Warning: Could not find Compute Engine default service account via display name. Trying project number based name.${RESET_FORMAT}"
        # Fallback using project number (less reliable but common pattern)
        COMPUTE_SA_EMAIL_FALLBACK="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
        echo "Attempting to grant Compute Engine SA ($COMPUTE_SA_EMAIL_FALLBACK) roles/cloudkms.signerVerifier role..."
        gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member serviceAccount:${COMPUTE_SA_EMAIL_FALLBACK} \
        --role roles/cloudkms.signerVerifier --condition=None --quiet
fi


echo "${CYAN_TEXT}${BOLD_TEXT}Step 14:${RESET_FORMAT} ${GREEN_TEXT}Installing the custom Cloud Build step for attestation.${RESET_FORMAT}"
cd ~ # Go to home directory before cloning
rm -rf cloud-builders-community # Clean up previous run
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation

# Use the corrected $REGION for custom builder build
echo "Submitting custom builder build in region: $REGION"
gcloud builds submit . --config cloudbuild.yaml --region=$REGION --quiet

cd ~/sample-app # Go back into sample-app

echo "${CYAN_TEXT}${BOLD_TEXT}Step 15:${RESET_FORMAT} ${GREEN_TEXT}Creating the enhanced Cloud Build configuration (cloudbuild.yaml).${RESET_FORMAT}"
# Define variables used in cloudbuild.yaml
SCAN_IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest"
PROD_IMAGE_URL="${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest"
ATTESTOR_NAME="projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}"
KEY_VERSION_PATH="projects/${PROJECT_ID}/locations/${KEY_LOCATION}/keyRings/${KEYRING}/cryptoKeys/${KEY_NAME}/cryptoKeyVersions/${KEY_VERSION}"

# Create the cloudbuild.yaml file matching Task 4 requirements
cat <<EOF > cloudbuild.yaml
steps:
    # 1. Build Step. (Matches TODO #1)
    - id: "build"
        name: 'gcr.io/cloud-builders/docker'
        args: ['build', '-t', '${SCAN_IMAGE_URL}', '.']
        waitFor: ['-'] # Start immediately

    # 2. Push to Artifact Registry (scanning repo). (Matches TODO #2)
    - id: "push-scan" # Clarified ID
        name: 'gcr.io/cloud-builders/docker'
        args: ['push', '${SCAN_IMAGE_URL}']
        waitFor: ['build'] # Wait for build

    # 3. Run a vulnerability scan. (Matches TODO #3)
    # Use 'us' location as specified in the lab instructions.
    - id: scan
        name: 'gcr.io/cloud-builders/gcloud'
        entrypoint: 'bash'
        args:
        - '-c'
        - |
            echo "Scanning image: ${SCAN_IMAGE_URL}"
            scan_result=\$(gcloud artifacts docker images scan \
                '${SCAN_IMAGE_URL}' \
                --location 'us' \
                --format="value(response.scan)") # Capture output directly
            if [ -z "\$scan_result" ]; then
                echo "ERROR: Scan command failed or produced no scan ID."
                exit 1 # Fail the step if scan ID is missing
            fi
            echo "Scan ID: \$scan_result"
            echo "\$scan_result" > /workspace/scan_id.txt
            echo "Scan ID written to /workspace/scan_id.txt"
        waitFor: ['push-scan'] # Wait for image to be pushed

    # 4. Analyze the result of the scan. IF CRITICAL vulnerabilities are found, fail the build. (Matches TODO #4)
    - id: severity-check # Changed ID to match lab example style
        name: 'gcr.io/cloud-builders/gcloud'
        entrypoint: 'bash'
        args:
        - '-c'
        - |
            if [ ! -s /workspace/scan_id.txt ]; then # Check if file exists and is not empty
                 echo "Error: Scan ID file /workspace/scan_id.txt not found or is empty."
                 exit 1
            fi
            scan_id=\$(cat /workspace/scan_id.txt)
            echo "Checking vulnerabilities for scan: \$scan_id"
            # Retry loop for listing vulnerabilities as API can be slow
            count=0
            max_retries=6 # Increased retries slightly
            delay=15    # Increased delay slightly
            vulns=""
            while [ \$count -lt \$max_retries ]; do
                # Check if scan is finished first (new addition for robustness)
                scan_status=\$(gcloud artifacts docker images describe \$scan_id --format='value(response.status)' 2>/dev/null)
                echo "Scan status (Attempt \$((count+1))): \$scan_status"
                if [ "\$scan_status" = "FINISHED_SUCCESS" ]; then
                    vulns=\$(gcloud artifacts docker images list-vulnerabilities \$scan_id \
                        --format="value(vulnerability.effectiveSeverity)")
                    if [ \$? -eq 0 ]; then
                         echo "Vulnerabilities retrieved."
                         break # Exit loop if successful retrieval
                    else
                         echo "Error retrieving vulnerabilities list even though scan finished."
                         # Continue loop to retry listing
                    fi
                elif [ "\$scan_status" = "FINISHED_UNSUPPORTED" ] || [ "\$scan_status" = "SCANNING_FAILED" ]; then
                        echo "ERROR: Scan finished with status \$scan_status."
                        exit 1 # Fail the step if scan failed
                fi
                count=\$((count + 1))
                if [ \$count -eq \$max_retries ]; then
                     break # Exit loop if max retries reached without success
                fi
                echo "Scan not finished or vulnerability list failed, retrying in \$delay seconds..."
                sleep \$delay
            done

            if [ \$count -eq \$max_retries ]; then
                echo "Error: Failed to get successful scan results after \$max_retries attempts."
                exit 1 # Fail the step if scan results couldn't be retrieved
            fi

            # Check for CRITICAL vulnerabilities (Matches TODO #4 requirement)
            if echo "\$vulns" | grep -Fxq CRITICAL; then
                echo "BUILD FAILED: CRITICAL vulnerabilities found!"
                exit 1 # Fail the build step
            else
                echo "Vulnerability check passed: No CRITICAL vulnerabilities found, congrats !"
                exit 0 # Pass the build step
            fi
        waitFor: ['scan']

    # 5. Sign the image only if the previous severity check passes. (Matches TODO #5)
    - id: 'create-attestation'
        name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest' # Custom builder
        args:
            - '--artifact-url=${SCAN_IMAGE_URL}'
            - '--attestor=${ATTESTOR_NAME}' # Correct attestor name variable
            - '--keyversion=${KEY_VERSION_PATH}' # Correct key version path variable
        waitFor: ['severity-check'] # Only run if severity check passed (exited 0)

    # 6. Re-tag the image for production and push it to the production repository. (Matches TODO #6)
    - id: "tag-for-prod" # Changed ID to be more descriptive
        name: 'gcr.io/cloud-builders/docker'
        args: ['tag', '${SCAN_IMAGE_URL}', '${PROD_IMAGE_URL}']
        waitFor: ['create-attestation'] # Wait for attestation

    - id: "push-to-prod" # Changed ID to match lab example style
        name: 'gcr.io/cloud-builders/docker'
        args: ['push', '${PROD_IMAGE_URL}']
        waitFor: ['tag-for-prod'] # Wait for tag

    # 7. Deploy to Cloud Run using the production image. (Matches TODO #7)
    # Note: --allow-unauthenticated is removed here as per lab flow (added later by script)
    - id: 'deploy-to-cloud-run'
        name: 'gcr.io/cloud-builders/gcloud'
        entrypoint: 'bash'
        args:
        - '-c'
        - |
            echo "Deploying image: ${PROD_IMAGE_URL} to Cloud Run service: auth-service in region ${REGION}"
            gcloud run deploy auth-service \
                --image=${PROD_IMAGE_URL} \
                --binary-authorization=default \
                --region=${REGION} \
                --platform=managed \
                --project=${PROJECT_ID} # Explicitly specify project
        waitFor: ['push-to-prod'] # Wait for prod image push

# 8. Image pushed to production repository. (Matches TODO #8)
images:
    - '${PROD_IMAGE_URL}' # The final image produced and relevant for output
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}Step 16:${RESET_FORMAT} ${YELLOW_TEXT}Submitting the enhanced Cloud Build to ${REGION} (EXPECTED TO FAIL DUE TO VULNERABILITY).${RESET_FORMAT}"
# Use the corrected $REGION for build submission
gcloud builds submit --region=$REGION --config=cloudbuild.yaml .

# --- Task 5: Fix the vulnerability and redeploy ---
echo "${CYAN_TEXT}${BOLD_TEXT}Step 17:${RESET_FORMAT} ${GREEN_TEXT}Updating Dockerfile to fix vulnerabilities.${RESET_FORMAT}"
# Use exact versions specified in Task 5 (Flask 3.0.3, Gunicorn 23.0.0, Werkzeug 3.0.4)
cat > ./Dockerfile << EOF
# Use the python:3.8-alpine base image specified in the task
FROM python:3.8-alpine

WORKDIR /app
COPY . ./

# Install Flask, Gunicorn, and Werkzeug with specific versions from Task 5
RUN pip install --no-cache-dir --upgrade pip && \
        pip install --no-cache-dir Flask==3.0.3 gunicorn==23.0.0 Werkzeug==3.0.4

# Use Gunicorn with PORT environment variable
CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}Step 18:${RESET_FORMAT} ${GREEN_TEXT}Re-submitting the Cloud Build with the fixed Dockerfile to ${REGION} (EXPECTED TO SUCCEED).${RESET_FORMAT}"
# Use the corrected $REGION for build submission
gcloud builds submit --region=$REGION --config=cloudbuild.yaml .

echo "${CYAN_TEXT}${BOLD_TEXT}Step 19:${RESET_FORMAT} ${YELLOW_TEXT}Waiting briefly before allowing unauthenticated access to Cloud Run service for testing in ${REGION}.${RESET_FORMAT}"
# Add a sleep to increase the chance the service exists after build submission.
# NOTE: This is not foolproof. Ideally, we'd poll the build status or the service status.
sleep 60 # Wait 60 seconds

echo "${CYAN_TEXT}${BOLD_TEXT}Step 19b:${RESET_FORMAT} ${GREEN_TEXT}Allowing unauthenticated access to Cloud Run service for testing in ${REGION}.${RESET_FORMAT}"
# Use the corrected $REGION
echo "Applying run.invoker role to allUsers for auth-service in region ${REGION}..."
gcloud run services add-iam-policy-binding auth-service \
    --region=$REGION \
    --member=allUsers \
    --role=roles/run.invoker \
    --platform=managed --quiet

echo "${YELLOW_TEXT}Check the Cloud Build history in the $REGION region. The build triggered in Step 16 should have failed (severity check). The build triggered in Step 18 should succeed.${RESET_FORMAT}"
echo "${YELLOW_TEXT}Waiting a bit longer for deployment to stabilize before getting URL...${RESET_FORMAT}"
sleep 30 # Extra wait before checking URL

SERVICE_URL=$(gcloud run services describe auth-service --platform=managed --region=$REGION --format='value(status.url)' 2>/dev/null)
if [ -n "$SERVICE_URL" ]; then
    echo "${YELLOW_TEXT}Verify the deployment by visiting the Cloud Run service URL:${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}${SERVICE_URL}${RESET_FORMAT}"
else
 echo "${RED_TEXT}Could not retrieve Cloud Run service URL. The deployment in the last build might still be in progress or failed. Check deployment status manually in the Cloud Run console for region ${REGION}.${RESET_FORMAT}"
fi
echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
