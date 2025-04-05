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

# Clear the screen
clear

# Print the welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Function to print command before execution
execute_command() {
  echo "${YELLOW_TEXT}---> Executing command:${RESET_FORMAT}"
  echo "${CYAN_TEXT}$@${RESET_FORMAT}"
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    echo "${RED_TEXT}---> Command failed with status $status: $@${RESET_FORMAT}"
    # Decide if you want to exit on failure: exit $status
  fi
  echo # Add a newline for better readability
  return $status
}

# Function to print message before execution (for non-standard commands like cat, read, export etc.)
prepare_to_execute() {
  echo "${YELLOW_TEXT}---> Preparing to execute:${RESET_FORMAT}"
  echo "${CYAN_TEXT}$@${RESET_FORMAT}"
  # No execution here, just printing
}
# Loop to run the script content twice
for i in {1..2}
do
  echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
  echo "${BLUE_TEXT}${BOLD_TEXT}         STARTING RUN $i of 2...       ${RESET_FORMAT}"
  echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
  echo

  read -p "Enter GCP Zone: " ZONE
  echo # Add newline after read

  prepare_to_execute "export ZONE"
  export ZONE

  prepare_to_execute "export REGION=\"\${ZONE%-*}\""
  export REGION="${ZONE%-*}"
  prepare_to_execute "export PROJECT_ID=\$(gcloud config get-value project)"
  export PROJECT_ID=$(gcloud config get-value project)
  prepare_to_execute "export PROJECT_NUMBER=\$(gcloud projects describe \$PROJECT_ID --format='value(projectNumber)')"
  export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
      --format='value(projectNumber)')
  echo # newline

  execute_command gcloud services enable \
    cloudkms.googleapis.com \
    cloudbuild.googleapis.com \
    container.googleapis.com \
    containerregistry.googleapis.com \
    artifactregistry.googleapis.com \
    containerscanning.googleapis.com \
    ondemandscanning.googleapis.com \
    binaryauthorization.googleapis.com

  execute_command gcloud artifacts repositories create artifact-scanning-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository" \
    --project=${PROJECT_ID} # Added project for clarity, may prevent errors in some contexts

  execute_command gcloud auth configure-docker $REGION-docker.pkg.dev --project=${PROJECT_ID}

  # Use a unique directory for each run to avoid conflicts
  RUN_DIR="vuln-scan-run-$i"
  prepare_to_execute "rm -rf ${RUN_DIR} && mkdir ${RUN_DIR} && cd ${RUN_DIR}"
  rm -rf ${RUN_DIR} # Clean up from previous potential failed run
  mkdir ${RUN_DIR}
  cd ${RUN_DIR}
  echo # newline

  prepare_to_execute "cat > ./Dockerfile << EOF ... EOF"
cat > ./Dockerfile << EOF
FROM python:3.8-alpine

# App
WORKDIR /app
COPY . ./

RUN pip3 install Flask==2.1.0
RUN pip3 install gunicorn==20.1.0
RUN pip3 install Werkzeug==2.2.2


CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app

EOF
  echo # newline

  prepare_to_execute "cat > ./main.py << EOF ... EOF"
cat > ./main.py << EOF
import os
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "Worlds")
    return "Hello {}!".format(name)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF
  echo # newline

  execute_command gcloud builds submit . -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image --project=${PROJECT_ID}

  prepare_to_execute "cat > ./vulnz_note.json << EOM ... EOM"
cat > ./vulnz_note.json << EOM
{
  "attestation": {
    "hint": {
      "human_readable_name": "Container Vulnerabilities attestation authority run $i"
    }
  }
}
EOM
  echo # newline

  # Make Note ID unique per run to avoid conflicts
  NOTE_ID=vulnz-note-run-$i
  prepare_to_execute "NOTE_ID=vulnz-note-run-$i" # Show variable assignment
  echo

  prepare_to_execute "curl -vvv -X POST ... create note ..."
  curl -vvv -X POST \
      -H "Content-Type: application/json"  \
      -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
      --data-binary @./vulnz_note.json  \
      "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"
  echo # newline

  prepare_to_execute "curl -vvv ... get note ..."
  curl -vvv  \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"
  echo # newline

  # Make Attestor ID unique per run
  ATTESTOR_ID=vulnz-attestor-run-$i
  prepare_to_execute "ATTESTOR_ID=vulnz-attestor-run-$i" # Show variable assignment
  echo

  execute_command gcloud container binauthz attestors create $ATTESTOR_ID \
      --attestation-authority-note=$NOTE_ID \
      --attestation-authority-note-project=${PROJECT_ID} \
      --project=${PROJECT_ID}

  execute_command gcloud container binauthz attestors list --project=${PROJECT_ID}

  # Project number should be the same, re-fetch just in case context changes
  prepare_to_execute "PROJECT_NUMBER=\$(gcloud projects describe \"\${PROJECT_ID}\"  --format=\"value(projectNumber)\")"
  PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}"  --format="value(projectNumber)")
  echo # newline

  prepare_to_execute "BINAUTHZ_SA_EMAIL=\"service-\${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com\""
  BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
  echo # newline

  # Update iam_request.json dynamically for the unique NOTE_ID
  prepare_to_execute "cat > ./iam_request.json << EOM ... EOM (dynamically setting NOTE_ID)"
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
  echo # newline

  prepare_to_execute "curl -X POST ... setIamPolicy ..."
  curl -X POST  \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      --data-binary @./iam_request.json \
      "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"
  echo # newline

  # KMS resources might need unique names per run or careful cleanup
  KEY_LOCATION=global # Global might conflict between runs if not cleaned. Consider regional if possible.
  KEYRING=binauthz-keys-run-$i
  KEY_NAME=codelab-key-run-$i
  KEY_VERSION=1 # Version usually starts at 1

  prepare_to_execute "KEY_LOCATION=global"
  prepare_to_execute "KEYRING=binauthz-keys-run-$i"
  prepare_to_execute "KEY_NAME=codelab-key-run-$i"
  prepare_to_execute "KEY_VERSION=1"
  echo

  # Add --project to KMS commands
  execute_command gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}" --project="${PROJECT_ID}"

  execute_command gcloud kms keys create "${KEY_NAME}" \
      --keyring="${KEYRING}" --location="${KEY_LOCATION}" \
      --purpose asymmetric-signing   \
      --default-algorithm="ec-sign-p256-sha256" \
      --project="${PROJECT_ID}"

  # Use beta command as in original script
  execute_command gcloud beta container binauthz attestors public-keys add  \
      --attestor="${ATTESTOR_ID}"  \
      --keyversion-project="${PROJECT_ID}"  \
      --keyversion-location="${KEY_LOCATION}" \
      --keyversion-keyring="${KEYRING}" \
      --keyversion-key="${KEY_NAME}" \
      --keyversion="${KEY_VERSION}" \
      --project="${PROJECT_ID}" # Attestor project

  execute_command gcloud container binauthz attestors list --project=${PROJECT_ID}

  prepare_to_execute "CONTAINER_PATH=$REGION-docker.pkg.dev/\${PROJECT_ID}/artifact-scanning-repo/sample-image"
  CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
  echo # newline

  # Ensure using the 'latest' tag explicitly if needed, or a specific digest
  prepare_to_execute "DIGEST=\$(gcloud container images describe \${CONTAINER_PATH}:latest --format='get(image_summary.digest)' --project=\${PROJECT_ID})"
  DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:latest \
      --format='get(image_summary.digest)' --project=${PROJECT_ID})
  echo # newline

  # Use beta command as in original script
  execute_command gcloud beta container binauthz attestations sign-and-create  \
      --artifact-url="${CONTAINER_PATH}@${DIGEST}" \
      --attestor="${ATTESTOR_ID}" \
      --attestor-project="${PROJECT_ID}" \
      --keyversion-project="${PROJECT_ID}" \
      --keyversion-location="${KEY_LOCATION}" \
      --keyversion-keyring="${KEYRING}" \
      --keyversion-key="${KEY_NAME}" \
      --keyversion="${KEY_VERSION}" \
      --project="${PROJECT_ID}" # Project where the command runs

  execute_command gcloud container binauthz attestations list \
     --attestor=$ATTESTOR_ID --attestor-project=${PROJECT_ID} \
     --project=${PROJECT_ID} # Project where the command runs

  # Make cluster name unique per run
  CLUSTER_NAME=binauthz-run-$i
  prepare_to_execute "CLUSTER_NAME=binauthz-run-$i"
  echo

  execute_command gcloud beta container clusters create ${CLUSTER_NAME} \
      --zone $ZONE  \
      --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE \
      --project=${PROJECT_ID}

  # Get credentials for the newly created cluster
  execute_command gcloud container clusters get-credentials ${CLUSTER_NAME} --zone $ZONE --project=${PROJECT_ID}


  execute_command gcloud projects add-iam-policy-binding ${PROJECT_ID} \
          --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
          --role="roles/container.developer" \
          --condition=None # Explicitly add no condition

  execute_command gcloud container binauthz policy export --project=${PROJECT_ID}

  prepare_to_execute "kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080"
  kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080
  echo # newline

  prepare_to_execute "kubectl get pods"
  kubectl get pods
  echo # newline

  prepare_to_execute "sleep 30"
  sleep 30
  echo # newline

  prepare_to_execute "kubectl delete pod hello-server"
  kubectl delete pod hello-server --ignore-not-found=true # Avoid error if pod failed to start
  echo # newline

  execute_command gcloud container binauthz policy export --project=${PROJECT_ID} > policy.yaml

  prepare_to_execute "cat > policy.yaml << EOM ... ALWAYS_DENY ..."
cat > policy.yaml << EOM
# Policy for Run $i - Initial DENY
globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: ALWAYS_DENY
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$PROJECT_ID/policy
EOM
  echo # newline

  execute_command gcloud container binauthz policy import policy.yaml --project=${PROJECT_ID}

  prepare_to_execute "kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080 (expecting failure)"
  kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080
  # Don't exit on expected failure here
  echo # newline

  prepare_to_execute "cat > policy.yaml << EOM ... ALWAYS_ALLOW ..."
cat > policy.yaml << EOM
# Policy for Run $i - Back to ALLOW
globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: ALWAYS_ALLOW
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$PROJECT_ID/policy
EOM
  echo # newline

  execute_command gcloud container binauthz policy import policy.yaml --project=${PROJECT_ID}

  execute_command gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/binaryauthorization.attestorsViewer \
    --condition=None

  execute_command gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/cloudkms.signerVerifier \
    --condition=None

  execute_command gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role roles/containeranalysis.notes.attacher \
    --condition=None

  execute_command gcloud projects add-iam-policy-binding ${PROJECT_ID} \
          --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
          --role="roles/iam.serviceAccountUser" \
          --condition=None

  execute_command gcloud projects add-iam-policy-binding ${PROJECT_ID} \
          --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
          --role="roles/ondemandscanning.admin" \
          --condition=None

  # Clone repo into a unique directory per run
  COMMUNITY_BUILDERS_DIR="cloud-builders-community-run-$i"
  prepare_to_execute "rm -rf ${COMMUNITY_BUILDERS_DIR} && git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git ${COMMUNITY_BUILDERS_DIR}"
  rm -rf ${COMMUNITY_BUILDERS_DIR}
  git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git ${COMMUNITY_BUILDERS_DIR}
  echo

  prepare_to_execute "cd ${COMMUNITY_BUILDERS_DIR}/binauthz-attestation"
  cd ${COMMUNITY_BUILDERS_DIR}/binauthz-attestation
  echo

  execute_command gcloud builds submit . --config cloudbuild.yaml --project=${PROJECT_ID}

  prepare_to_execute "cd ../../"
  cd ../..
  echo

  prepare_to_execute "rm -rf ${COMMUNITY_BUILDERS_DIR}"
  rm -rf ${COMMUNITY_BUILDERS_DIR}
  echo

  # Update cloudbuild.yaml with unique attestor/kms info for this run
  prepare_to_execute "cat > ./cloudbuild.yaml << EOF ... (dynamically setting run-specific vars)"
cat > ./cloudbuild.yaml << EOF
# Cloud Build config for Run $i
steps:

# build
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

# additional CICD checks (not shown)

#Retag
- id: "retag"
  name: 'gcr.io/cloud-builders/docker'
  args: ['tag',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good-run-$i']


#pushing to artifact registry
- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good-run-$i']


#Sign the image only if the previous severity check passes
- id: 'create-attestation'
  name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest'
  args:
    - '--artifact-url'
    - '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good-run-$i'
    - '--attestor'
    - 'projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}' # Unique Attestor ID
    - '--keyversion'
    - 'projects/${PROJECT_ID}/locations/${KEY_LOCATION}/keyRings/${KEYRING}/cryptoKeys/${KEY_NAME}/cryptoKeyVersions/${KEY_VERSION}' # Unique Key Version path

images:
  - $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good-run-$i
EOF
  echo # newline

  execute_command gcloud builds submit --project=${PROJECT_ID} --config=./cloudbuild.yaml . # Specify config file

  # Update policy to use the unique attestor and cluster for this run
  prepare_to_execute "COMPUTE_ZONE=$ZONE" # Variable already set, just showing
  COMPUTE_ZONE=$ZONE # Use actual zone here, not region
  prepare_to_execute "cat > binauth_policy.yaml << EOM ... (dynamically setting run-specific vars)"
cat > binauth_policy.yaml << EOM
# Binauthz policy for Run $i
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: REQUIRE_ATTESTATION
  requireAttestationsBy:
  - projects/${PROJECT_ID}/attestors/${ATTESTOR_ID} # Unique Attestor
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  # Use the actual zone and unique cluster name here
  ${COMPUTE_ZONE}.${CLUSTER_NAME}:
    evaluationMode: REQUIRE_ATTESTATION
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    requireAttestationsBy:
    - projects/${PROJECT_ID}/attestors/${ATTESTOR_ID} # Unique Attestor
EOM
  echo # newline

  execute_command gcloud beta container binauthz policy import binauth_policy.yaml --project=${PROJECT_ID}

  # Use the image tagged for this specific run
  GOOD_IMAGE_TAG="good-run-$i"
  prepare_to_execute "GOOD_IMAGE_TAG=\"good-run-$i\""
  prepare_to_execute "CONTAINER_PATH=$REGION-docker.pkg.dev/\${PROJECT_ID}/artifact-scanning-repo/sample-image" # Base path
  CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
  prepare_to_execute "DIGEST=\$(gcloud container images describe \${CONTAINER_PATH}:${GOOD_IMAGE_TAG} --format='get(image_summary.digest)' --project=\${PROJECT_ID})"
  DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:${GOOD_IMAGE_TAG} \
      --format='get(image_summary.digest)' --project=${PROJECT_ID})
  echo # newline

  # Update deploy.yaml with the correct signed image digest and unique name/label
  DEPLOYMENT_NAME="deb-httpd-run-$i"
  prepare_to_execute "DEPLOYMENT_NAME=\"deb-httpd-run-$i\""
  prepare_to_execute "cat > deploy.yaml << EOM ... (dynamically setting image digest and deployment name)"
cat > deploy.yaml << EOM
# Deployment for Run $i - Signed Image
apiVersion: v1
kind: Service
metadata:
  name: ${DEPLOYMENT_NAME}-svc # Unique service name
spec:
  selector:
    app: ${DEPLOYMENT_NAME} # Match unique label
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT_NAME} # Unique deployment name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOYMENT_NAME} # Unique label selector
  template:
    metadata:
      labels:
        app: ${DEPLOYMENT_NAME} # Unique label
    spec:
      containers:
      - name: deb-httpd # Container name can be reused
        image: ${CONTAINER_PATH}@${DIGEST} # Specific signed digest
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"
EOM
  echo # newline

  prepare_to_execute "kubectl apply -f deploy.yaml (signed image, should succeed)"
  kubectl apply -f deploy.yaml
  echo # newline

  # Build and push a 'bad' image specific to this run
  BAD_IMAGE_TAG="bad-run-$i"
  prepare_to_execute "BAD_IMAGE_TAG=\"bad-run-$i\""
  execute_command docker build -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:${BAD_IMAGE_TAG} .

  execute_command docker push $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:${BAD_IMAGE_TAG}

  prepare_to_execute "CONTAINER_PATH=$REGION-docker.pkg.dev/\${PROJECT_ID}/artifact-scanning-repo/sample-image" # Base path again
  CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
  prepare_to_execute "DIGEST=\$(gcloud container images describe \${CONTAINER_PATH}:${BAD_IMAGE_TAG} --format='get(image_summary.digest)' --project=\${PROJECT_ID})"
  DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:${BAD_IMAGE_TAG} \
      --format='get(image_summary.digest)' --project=${PROJECT_ID})
  echo # newline

  # Update deploy.yaml for the unsigned 'bad' image, keep unique name
  prepare_to_execute "cat > deploy.yaml << EOM ... (dynamically setting unsigned image digest)"
cat > deploy.yaml << EOM
# Deployment for Run $i - Unsigned Image Attempt
apiVersion: v1
kind: Service
metadata:
  name: ${DEPLOYMENT_NAME}-svc # Keep unique service name
spec:
  selector:
    app: ${DEPLOYMENT_NAME} # Match unique label
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT_NAME} # Keep unique deployment name (will cause update)
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${DEPLOYMENT_NAME} # Keep unique label selector
  template:
    metadata:
      labels:
        app: ${DEPLOYMENT_NAME} # Keep unique label
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${DIGEST} # Specific unsigned digest
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"
EOM
  echo # newline

  prepare_to_execute "kubectl apply -f deploy.yaml (unsigned image, expect failure/rejection)"
  kubectl apply -f deploy.yaml
  # Don't exit on expected failure
  echo # newline

  # Go back to the parent directory before the next loop iteration
  prepare_to_execute "cd .."
  cd ..
  echo

  echo "${GREEN_TEXT}${BOLD_TEXT}--------------------------------------${RESET_FORMAT}"
  echo "${GREEN_TEXT}${BOLD_TEXT}         COMPLETED RUN $i of 2        ${RESET_FORMAT}"
  echo "${GREEN_TEXT}${BOLD_TEXT}--------------------------------------${RESET_FORMAT}"
  echo

done # End of the for loop (runs twice)

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo