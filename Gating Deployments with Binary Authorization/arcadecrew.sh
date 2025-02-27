#!/bin/bash

# Bright Foreground Colors
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

# Displaying start message
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Prompt user for input
echo "${GREEN_TEXT}${BOLD_TEXT}Please enter the zone for your GCP resources (e.g., us-central1-a):${RESET_FORMAT}"
read -p "Zone: " ZONE
export ZONE

export REGION="${ZONE%-*}"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
    --format='value(projectNumber)')

echo "${CYAN_TEXT}${BOLD_TEXT}Enabling required GCP services...${RESET_FORMAT}"
gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com 

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Docker repository in Artifact Registry...${RESET_FORMAT}"
gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="Docker repository"

echo "${CYAN_TEXT}${BOLD_TEXT}Configuring Docker to use the Artifact Registry...${RESET_FORMAT}"
gcloud auth configure-docker $REGION-docker.pkg.dev

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a directory for vulnerability scanning...${RESET_FORMAT}"
mkdir vuln-scan && cd vuln-scan

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a Dockerfile...${RESET_FORMAT}"
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

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a main.py file...${RESET_FORMAT}"
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

echo "${CYAN_TEXT}${BOLD_TEXT}Building and submitting the Docker image to Artifact Registry...${RESET_FORMAT}"
gcloud builds submit . -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a vulnerability note...${RESET_FORMAT}"
cat > ./vulnz_note.json << EOM
{
  "attestation": {
    "hint": {
      "human_readable_name": "Container Vulnerabilities attestation authority"
    }
  }
}
EOM

NOTE_ID=vulnz_note

echo "${CYAN_TEXT}${BOLD_TEXT}Creating the vulnerability note in Container Analysis...${RESET_FORMAT}"
curl -vvv -X POST \
    -H "Content-Type: application/json"  \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @./vulnz_note.json  \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

echo "${CYAN_TEXT}${BOLD_TEXT}Fetching the vulnerability note details...${RESET_FORMAT}"
curl -vvv  \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

ATTESTOR_ID=vulnz-attestor

echo "${CYAN_TEXT}${BOLD_TEXT}Creating an attestor for Binary Authorization...${RESET_FORMAT}"
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=${PROJECT_ID}

echo "${CYAN_TEXT}${BOLD_TEXT}Listing all attestors...${RESET_FORMAT}"
gcloud container binauthz attestors list

PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}"  --format="value(projectNumber)")

BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating an IAM request JSON file...${RESET_FORMAT}"
cat > ./iam_request.json << EOM
{
  'resource': 'projects/${PROJECT_ID}/notes/${NOTE_ID}',
  'policy': {
    'bindings': [
      {
        'role': 'roles/containeranalysis.notes.occurrences.viewer',
        'members': [
          'serviceAccount:${BINAUTHZ_SA_EMAIL}'
        ]
      }
    ]
  }
}
EOM

echo "${CYAN_TEXT}${BOLD_TEXT}Setting IAM policy for the vulnerability note...${RESET_FORMAT}"
curl -X POST  \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data-binary @./iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=codelab-key
KEY_VERSION=1

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a keyring for KMS...${RESET_FORMAT}"
gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a key for KMS...${RESET_FORMAT}"
gcloud kms keys create "${KEY_NAME}" \
    --keyring="${KEYRING}" --location="${KEY_LOCATION}" \
    --purpose asymmetric-signing   \
    --default-algorithm="ec-sign-p256-sha256"

echo "${CYAN_TEXT}${BOLD_TEXT}Adding the public key to the attestor...${RESET_FORMAT}"
gcloud beta container binauthz attestors public-keys add  \
    --attestor="${ATTESTOR_ID}"  \
    --keyversion-project="${PROJECT_ID}"  \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

echo "${CYAN_TEXT}${BOLD_TEXT}Listing all attestors...${RESET_FORMAT}"
gcloud container binauthz attestors list

CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:latest \
    --format='get(image_summary.digest)')

echo "${CYAN_TEXT}${BOLD_TEXT}Signing and creating an attestation for the container image...${RESET_FORMAT}"
gcloud beta container binauthz attestations sign-and-create  \
    --artifact-url="${CONTAINER_PATH}@${DIGEST}" \
    --attestor="${ATTESTOR_ID}" \
    --attestor-project="${PROJECT_ID}" \
    --keyversion-project="${PROJECT_ID}" \
    --keyversion-location="${KEY_LOCATION}" \
    --keyversion-keyring="${KEYRING}" \
    --keyversion-key="${KEY_NAME}" \
    --keyversion="${KEY_VERSION}"

echo "${CYAN_TEXT}${BOLD_TEXT}Listing all attestations...${RESET_FORMAT}"
gcloud container binauthz attestations list \
   --attestor=$ATTESTOR_ID --attestor-project=${PROJECT_ID}

echo "${CYAN_TEXT}${BOLD_TEXT}Creating a GKE cluster with Binary Authorization enabled...${RESET_FORMAT}"
gcloud beta container clusters create binauthz \
    --zone $ZONE  \
    --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE

echo "${CYAN_TEXT}${BOLD_TEXT}Granting the Cloud Build service account the necessary permissions...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/container.developer"

echo "${CYAN_TEXT}${BOLD_TEXT}Exporting the Binary Authorization policy...${RESET_FORMAT}"
gcloud container binauthz policy export

echo "${CYAN_TEXT}${BOLD_TEXT}Deploying a sample pod to the GKE cluster...${RESET_FORMAT}"
kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080

echo "${CYAN_TEXT}${BOLD_TEXT}Listing all pods...${RESET_FORMAT}"
kubectl get pods

sleep 30

echo "${CYAN_TEXT}${BOLD_TEXT}Deleting the sample pod...${RESET_FORMAT}"
kubectl delete pod hello-server

echo "${CYAN_TEXT}${BOLD_TEXT}Exporting the Binary Authorization policy to a file...${RESET_FORMAT}"
gcloud container binauthz policy export  > policy.yaml

echo "${CYAN_TEXT}${BOLD_TEXT}Updating the Binary Authorization policy to always deny...${RESET_FORMAT}"
cat > policy.yaml << EOM

globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: ALWAYS_DENY
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$PROJECT_ID/policy

EOM

echo "${CYAN_TEXT}${BOLD_TEXT}Importing the updated Binary Authorization policy...${RESET_FORMAT}"
gcloud container binauthz policy import policy.yaml

echo "${CYAN_TEXT}${BOLD_TEXT}Attempting to deploy a sample pod again (should fail due to the policy)...${RESET_FORMAT}"
kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080

echo "${CYAN_TEXT}${BOLD_TEXT}Updating the Binary Authorization policy to always allow...${RESET_FORMAT}"
cat > policy.yaml << EOM

globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: ALWAYS_ALLOW
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
name: projects/$PROJECT_ID/policy

EOM

echo "${CYAN_TEXT}${BOLD_TEXT}Importing the updated Binary Authorization policy...${RESET_FORMAT}"
gcloud container binauthz policy import policy.yaml


echo
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Starting Binary Authorization Policy Import and IAM Bindings...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Importing the Binary Authorization policy...${RESET_FORMAT}"
gcloud container binauthz policy import policy.yaml

echo "${YELLOW_TEXT}${BOLD_TEXT}Granting Cloud Build service account permission to view attestors...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role roles/binaryauthorization.attestorsViewer

echo "${YELLOW_TEXT}${BOLD_TEXT}Granting Cloud Build service account permission to sign with Cloud KMS...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role roles/cloudkms.signerVerifier

echo "${YELLOW_TEXT}${BOLD_TEXT}Granting Cloud Build service account permission to attach notes in Container Analysis...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
  --role roles/containeranalysis.notes.attacher

echo "${YELLOW_TEXT}${BOLD_TEXT}Granting Cloud Build service account user permissions...${RESET_FORMAT}"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"

echo "${YELLOW_TEXT}${BOLD_TEXT}Granting Cloud Build service account On-Demand Scanning admin permissions...${RESET_FORMAT}"        
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="roles/ondemandscanning.admin"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Cloning, Building, and Submitting the Binauthz Attestation Builder...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Cloning the Cloud Builders Community repository...${RESET_FORMAT}"
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
echo "${GREEN_TEXT}${BOLD_TEXT}Navigating to the binauthz-attestation directory...${RESET_FORMAT}"
cd cloud-builders-community/binauthz-attestation
echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build configuration...${RESET_FORMAT}"
gcloud builds submit . --config cloudbuild.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}Navigating back to the parent directory and cleaning up...${RESET_FORMAT}"
cd ../..
rm -rf cloud-builders-community
echo
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Creating and Submitting the Cloud Build Configuration...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Creating the cloudbuild.yaml file...${RESET_FORMAT}"
cat > ./cloudbuild.yaml << EOF
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
  args: ['tag',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']


#pushing to artifact registry
- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good']


#Sign the image only if the previous severity check passes
- id: 'create-attestation'
  name: 'gcr.io/${PROJECT_ID}/binauthz-attestation:latest'
  args:
    - '--artifact-url'
    - '$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good'
    - '--attestor'
    - 'projects/${PROJECT_ID}/attestors/$ATTESTOR_ID'
    - '--keyversion'
    - 'projects/${PROJECT_ID}/locations/$KEY_LOCATION/keyRings/$KEYRING/cryptoKeys/$KEY_NAME/cryptoKeyVersions/$KEY_VERSION'



images:
  - $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:good
EOF

echo "${GREEN_TEXT}${BOLD_TEXT}Submitting the Cloud Build...${RESET_FORMAT}"
gcloud builds submit

echo
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Updating Binary Authorization Policy to Require Attestations...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo

COMPUTE_ZONE=$REGION
echo "${GREEN_TEXT}${BOLD_TEXT}Creating binauth_policy.yaml with required attestations...${RESET_FORMAT}"
cat > binauth_policy.yaml << EOM
defaultAdmissionRule:
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  evaluationMode: REQUIRE_ATTESTATION
  requireAttestationsBy:
  - projects/${PROJECT_ID}/attestors/vulnz-attestor
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  ${COMPUTE_ZONE}.binauthz:
    evaluationMode: REQUIRE_ATTESTATION
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    requireAttestationsBy:
    - projects/${PROJECT_ID}/attestors/vulnz-attestor
EOM

echo "${GREEN_TEXT}${BOLD_TEXT}Importing the updated Binary Authorization policy...${RESET_FORMAT}"
gcloud beta container binauthz policy import binauth_policy.yaml
echo
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Deploying a Valid Container Image...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo

CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

echo "${GREEN_TEXT}${BOLD_TEXT}Fetching the digest of the 'good' container image...${RESET_FORMAT}"
DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:good \
    --format='get(image_summary.digest)')

echo "${GREEN_TEXT}${BOLD_TEXT}Creating the deploy.yaml file for the valid deployment...${RESET_FORMAT}"
cat > deploy.yaml << EOM
apiVersion: v1
kind: Service
metadata:
  name: deb-httpd
spec:
  selector:
    app: deb-httpd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-httpd
  template:
    metadata:
      labels:
        app: deb-httpd
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${DIGEST}
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"

EOM

echo "${GREEN_TEXT}${BOLD_TEXT}Applying the deployment for the valid image...${RESET_FORMAT}"
kubectl apply -f deploy.yaml
echo
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}   Deploying an Invalid Container Image (Should Fail)...${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Building a new 'bad' container image locally...${RESET_FORMAT}"
docker build -t $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:bad .

echo "${YELLOW_TEXT}${BOLD_TEXT}Pushing the 'bad' container image to the Artifact Registry...${RESET_FORMAT}"
docker push $REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image:bad

CONTAINER_PATH=$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image

echo "${YELLOW_TEXT}${BOLD_TEXT}Fetching the digest of the 'bad' container image...${RESET_FORMAT}"
DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:bad \
    --format='get(image_summary.digest)')

echo "${YELLOW_TEXT}${BOLD_TEXT}Updating deploy.yaml to point to the 'bad' image...${RESET_FORMAT}"
cat > deploy.yaml << EOM
apiVersion: v1
kind: Service
metadata:
  name: deb-httpd
spec:
  selector:
    app: deb-httpd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-httpd
  template:
    metadata:
      labels:
        app: deb-httpd
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${DIGEST}
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"

EOM
echo "${YELLOW_TEXT}${BOLD_TEXT}Attempting to apply the deployment with the 'bad' image... (This should fail) ${RESET_FORMAT}"
kubectl apply -f deploy.yaml
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo "${GREEN_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}                      Lab Completed Successfully.                        ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}--------------------------------------------------------------------${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo