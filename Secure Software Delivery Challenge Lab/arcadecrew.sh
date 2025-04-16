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
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION: ${RESET_FORMAT}" REGION

# Export variables after collecting input
export REGION

echo "${GREEN_TEXT}${BOLD_TEXT}Enabling required GCP services...${RESET_FORMAT}"
gcloud services enable \
    cloudkms.googleapis.com \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    container.googleapis.com \
    containerregistry.googleapis.com \
    artifactregistry.googleapis.com \
    containerscanning.googleapis.com \
    ondemandscanning.googleapis.com \
    binaryauthorization.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a sample application directory and downloading sample files...${RESET_FORMAT}"
mkdir sample-app && cd sample-app
gcloud storage cp gs://spls/gsp521/* .

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating Artifact Registry repositories for scanning and production...${RESET_FORMAT}"
gcloud artifacts repositories create artifact-scanning-repo \
--repository-format=docker \
--location=$REGION \
--description="Scanning repository"

gcloud artifacts repositories create artifact-prod-repo \
--repository-format=docker \
--location=$REGION \
--description="Production repository"

echo "${BLUE_TEXT}${BOLD_TEXT}Fetching project details...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

echo "${GREEN_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} $PROJECT_ID"
echo "${GREEN_TEXT}${BOLD_TEXT}Project Number:${RESET_FORMAT} $PROJECT_NUMBER"

echo "${CYAN_TEXT}${BOLD_TEXT}Listing all service accounts in the project...${RESET_FORMAT}"
gcloud iam service-accounts list

echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM policy bindings for required roles...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/ondemandscanning.admin"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Enabling Cloud Build service...${RESET_FORMAT}"
gcloud services enable cloudbuild.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Cloud Build configuration file...${RESET_FORMAT}"
cat > cloudbuild.yaml <<EOF_CP
steps:

# Build Step
- id: "build"
    name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '${REGION}-docker.pkg.dev/\${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
    waitFor: ['-']

# Push to Artifact Registry
- id: "push"
    name: 'gcr.io/cloud-builders/docker'
    args: ['push', '${REGION}-docker.pkg.dev/\${PROJECT_ID}/artifact-scanning-repo/sample-image']

# Images section
images:
    - ${REGION}-docker.pkg.dev/\${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF_CP

echo "${BLUE_TEXT}${BOLD_TEXT}Submitting the build to Cloud Build...${RESET_FORMAT}"
gcloud builds submit --region=$REGION

echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for the build to complete...${RESET_FORMAT}"
sleep 15

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a vulnerability note for attestation...${RESET_FORMAT}"
cat > ./vulnerability_note.json <<EOM
{
    "attestation": {
        "hint": {
            "human_readable_name": "Container Vulnerabilities attestation authority"
        }
    }
}
EOM

# Set the note ID
NOTE_ID=vulnerability_note

echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating a note using the Container Analysis API...${RESET_FORMAT}"
curl -vvv -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./vulnerability_note.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

curl -vvv \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating an attestor for Binary Authorization...${RESET_FORMAT}"
# Define the variables
ATTESTOR_ID="vulnerability-attestor"
NOTE_ID=vulnerability_note

# Create the attestor
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=$DEVSHELL_PROJECT_ID

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

echo "${YELLOW_TEXT}${BOLD_TEXT}Setting IAM policy for the attestation note...${RESET_FORMAT}"
cat > ./iam_request.json << EOM
{
    "resource": "projects/${PROJECT_ID}/notes/${NOTE_ID}",
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

curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a KMS keyring and key for signing...${RESET_FORMAT}"
KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=lab-key
KEY_VERSION=1

gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

gcloud kms keys create "${KEY_NAME}" \
    --keyring="${KEYRING}" \
    --location="${KEY_LOCATION}" \
    --purpose asymmetric-signing \
    --default-algorithm="ec-sign-p256-sha256"

gcloud beta container binauthz attestors public-keys add \
    --attestor="${ATTESTOR_ID}" \
    --keyversion-project="${PROJECT_ID}" \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

echo "${MAGENTA_TEXT}${BOLD_TEXT}Exporting and importing Binary Authorization policy...${RESET_FORMAT}"
gcloud container binauthz policy export > cp_policy.yaml

cat > cp_policy.yaml << EOM
defaultAdmissionRule:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: REQUIRE_ATTESTATION
    requireAttestationsBy:
        - projects/${PROJECT_ID}/attestors/vulnerability-attestor
globalPolicyEvaluationMode: ENABLE
name: projects/${PROJECT_ID}/policy
EOM

gcloud container binauthz policy import cp_policy.yaml

echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy bindings for required roles...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/binaryauthorization.attestorsViewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/cloudkms.signerVerifier"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --role="roles/cloudkms.signerVerifier"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/containeranalysis.notes.attacher"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/ondemandscanning.admin"

echo "${BLUE_TEXT}${BOLD_TEXT}Cloning the community repository for Binary Authorization attestation...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation
gcloud builds submit . --config cloudbuild.yaml
cd ../..
rm -rf cloud-builders-community

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a new Cloud Build configuration file for the pipeline...${RESET_FORMAT}"
cat > cloudbuild.yaml << EOF_CP
steps:
# TODO: #1. Build Step
- id: "build"
    name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest', '.']
    waitFor: ['-']
# TODO: #2. Push to Artifact Registry
- id: "push"
    name: 'gcr.io/cloud-builders/docker'
    args: ['push',  '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest']
# TODO: #3. Run a vulnerability scan
- id: scan
    name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
    - '-c'
    - |
            (gcloud artifacts docker images scan \\
            ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest \\
            --location us \\
            --format="value(response.scan)") > /workspace/scan_id.txt
# TODO: #4. Analyze the result of the scan
- id: severity check
    name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
    - '-c'
    - |
            gcloud artifacts docker images list-vulnerabilities \$(cat /workspace/scan_id.txt) \\
            --format="value(vulnerability.effectiveSeverity)" | if grep -Fxq CRITICAL; \\
            then echo "Failed vulnerability check for CRITICAL level" && exit 1; else echo \\
            "No CRITICAL vulnerability found, congrats !" && exit 0; fi
# TODO: #5. Sign the image only if the previous severity check passes
- id: 'create-attestation'
    name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest'
    args:
        - '--artifact-url'
        - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest'
        - '--attestor'
        - 'projects/${PROJECT_ID}/attestors/vulnerability-attestor'
        - '--keyversion'
        - 'projects/${PROJECT_ID}/locations/global/keyRings/binauthz-keys/cryptoKeys/lab-key/cryptoKeyVersions/1'
# TODO: #6. Re-tag the image for production and push it to the production repository using the latest tag
- id: "push-to-prod"
    name: 'gcr.io/cloud-builders/docker'
    args: 
        - 'tag' 
        - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest'
        - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest'
- id: "push-to-prod-final"
    name: 'gcr.io/cloud-builders/docker'
    args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest']
# TODO: #7. Deploy to Cloud Run
- id: 'deploy-to-cloud-run'
    name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
    - '-c'
    - |
        gcloud run deploy auth-service --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest \
        --binary-authorization=default --region=$REGION --allow-unauthenticated
# TODO: #8. Images section
images:
    - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest
EOF_CP

echo "${BLUE_TEXT}${BOLD_TEXT}Submitting the build pipeline to Cloud Build...${RESET_FORMAT}"
gcloud builds submit  --region=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Dockerfile for the sample application...${RESET_FORMAT}"
cat > ./Dockerfile << EOF
FROM python:3.8-alpine
# App
WORKDIR /app
COPY . ./
RUN pip3 install Flask==3.0.3
RUN pip3 install gunicorn==23.0.0
RUN pip3 install Werkzeug==3.0.4
CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app
EOF

echo "${MAGENTA_TEXT}${BOLD_TEXT}Submitting the Dockerfile to Cloud Build...${RESET_FORMAT}"
gcloud builds submit --region=$REGION

echo "${CYAN_TEXT}${BOLD_TEXT}Adding IAM policy binding for Cloud Run service...${RESET_FORMAT}"
gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker auth-service

echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
