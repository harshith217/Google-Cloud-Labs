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
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}         STARTING EXECUTION...       ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${GREEN_TEXT}Fetching project details and setting environment variables.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
    --format='value(projectNumber)')
export ZONE=$(gcloud compute project-info describe \
    --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

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
    binaryauthorization.googleapis.com

echo "${CYAN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Setting up the sample application.${RESET_FORMAT}"
mkdir sample-app && cd sample-app
gcloud storage cp gs://spls/gsp521/* .

echo "${CYAN_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${GREEN_TEXT}Creating Artifact Registry repositories.${RESET_FORMAT}"
gcloud artifacts repositories create artifact-scanning-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Scanning repository"

gcloud artifacts repositories create artifact-prod-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Production repository"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${GREEN_TEXT}Configuring Docker authentication.${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev

echo "${CYAN_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${GREEN_TEXT}Adding IAM policy bindings.${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/ondemandscanning.admin"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${GREEN_TEXT}Creating a Cloud Build configuration file.${RESET_FORMAT}"
cat > cloudbuild.yaml <<EOF
steps:

# TODO: #1. Build Step. Replace the <image-name> placeholder with the correct value.
- id: "build"
    name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
    waitFor: ['-']

# TODO: #2. Push to Artifact Registry. Replace the <image-name> placeholder with the correct value.
- id: "push"
    name: 'gcr.io/cloud-builders/docker'
    args: ['push',  '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image']


## More steps will be added here in a later section

# TODO: #8. Replace <image-name> placeholder with the value from the build step.
images:
    - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

echo "${CYAN_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} ${GREEN_TEXT}Submitting the Cloud Build configuration.${RESET_FORMAT}"
gcloud builds submit

echo "${CYAN_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} ${GREEN_TEXT}Creating a vulnerability note.${RESET_FORMAT}"
cat > ./vulnerability_note.json <<EOM
{
    "attestation": {
        "hint": {
            "human_readable_name": "Container Vulnerabilities attestation authority"
        }
    }
}
EOM

NOTE_ID=vulnerability_note
curl -vvv -X POST \
    -H "Content-Type: application/json"  \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @./vulnerability_note.json  \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

curl -vvv -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

echo "${CYAN_TEXT}${BOLD_TEXT}Step 10:${RESET_FORMAT} ${GREEN_TEXT}Creating an attestor.${RESET_FORMAT}"
ATTESTOR_ID=vulnerability-attestor
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=${PROJECT_ID}

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}"  --format="value(projectNumber)")

BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

cat > ./iam_request.json <<EOM
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

curl -X POST  \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=lab-key
KEY_VERSION=1

echo "${CYAN_TEXT}${BOLD_TEXT}Step 11:${RESET_FORMAT} ${GREEN_TEXT}Creating a KMS keyring and key.${RESET_FORMAT}"
gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

gcloud kms keys create "${KEY_NAME}" \
    --keyring="${KEYRING}" --location="${KEY_LOCATION}" \
    --purpose asymmetric-signing   \
    --default-algorithm="ec-sign-p256-sha256"

gcloud beta container binauthz attestors public-keys add  \
    --attestor="${ATTESTOR_ID}"  \
    --keyversion-project="${PROJECT_ID}"  \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

gcloud container binauthz policy export > my_policy.yaml

cat > my_policy.yaml <<EOM
defaultAdmissionRule:
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    evaluationMode: REQUIRE_ATTESTATION
    requireAttestationsBy:
        - projects/${PROJECT_ID}/attestors/vulnerability-attestor
globalPolicyEvaluationMode: ENABLE
name: projects/${PROJECT_ID}/policy
EOM

gcloud container binauthz policy import my_policy.yaml

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/binaryauthorization.attestorsViewer

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/cloudkms.signerVerifier

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com --role roles/cloudkms.signerVerifier

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/containeranalysis.notes.attacher

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/ondemandscanning.admin"

git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation
gcloud builds submit . --config cloudbuild.yaml
cd ../..
rm -rf cloud-builders-community

cat <<EOF > cloudbuild.yaml
steps:

- id: "build"
    name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest', '.']
    waitFor: ['-']

- id: "push"
    name: 'gcr.io/cloud-builders/docker'
    args: ['push',  '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest']

- id: scan
    name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
        - '-c'
        - |
            (gcloud artifacts docker images scan \\
            <command url> \\
            --location us \\
            --format="value(response.scan)") > /workspace/scan_id.txt

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

- id: 'create-attestation'
    name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest'
    args:
        - '--artifact-url'
        - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest'
        - '--attestor'
        - 'projects/${PROJECT_ID}/attestors/vulnerability-attestor'
        - '--keyversion'
        - 'projects/${PROJECT_ID}/locations/global/keyRings/binauthz-keys/cryptoKeys/lab-key/cryptoKeyVersions/1'

- id: "push-to-prod"
    name: 'gcr.io/cloud-builders/docker'
    args: 
        - 'tag' 
        - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest'
        - '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest'
- id: "push-to-prod-final"
    name: 'gcr.io/cloud-builders/docker'
    args: ['push', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-prod-repo/sample-image:latest']

- id: 'deploy-to-cloud-run'
    name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'bash'
    args:
        - '-c'
        - |
            gcloud run deploy auth-service --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest \
            --binary-authorization=default --region=$REGION --allow-unauthenticated

images:
    - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest
EOF

sed -i "s|<command url>|${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:latest|g" cloudbuild.yaml

gcloud builds submit

cat > ./Dockerfile <<EOF
FROM python:3.8-alpine

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==3.0.3
RUN pip3 install gunicorn==23.0.0
RUN pip3 install Werkzeug==3.0.4

CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app

EOF

gcloud builds submit

gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker auth-service

echo
echo "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
