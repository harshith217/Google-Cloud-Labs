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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Attempting to determine the default Google Cloud Zone...${RESET_FORMAT}"
ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])" 2>/dev/null)

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}🤔 Default zone could not be auto-detected.${RESET_FORMAT}"
  while [ -z "$ZONE" ]; do
    read -p "${WHITE_TEXT}${BOLD_TEXT}⌨️ Please enter the ZONE: ${RESET_FORMAT}" ZONE
    if [ -z "$ZONE" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}🚫 Zone cannot be empty. Please provide a valid zone.${RESET_FORMAT}"
    fi
  done
fi
export ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Zone set to: $ZONE${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Attempting to determine the default Google Cloud Region...${RESET_FORMAT}"
REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])" 2>/dev/null)

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}🤔 Default region could not be auto-detected.${RESET_FORMAT}"
  if [ -n "$ZONE" ]; then
    echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Trying to derive region from the provided zone: $ZONE${RESET_FORMAT}"
    REGION="${ZONE%-*}"
    if [ -z "$REGION" ] || [ "$REGION" == "$ZONE" ]; then
        echo "${RED_TEXT}${BOLD_TEXT}❌ Failed to derive region from zone. Region remains unknown.${RESET_FORMAT}"
    else
        echo "${GREEN_TEXT}${BOLD_TEXT}👍 Region derived as: $REGION${RESET_FORMAT}"
    fi
  else
    echo "${RED_TEXT}${BOLD_TEXT}⚠️ Zone is not set, so region cannot be derived automatically.${RESET_FORMAT}"
  fi
fi

if [ -z "$REGION" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}🤔 Region still undetermined. Manual input required.${RESET_FORMAT}"
  while [ -z "$REGION" ]; do
    read -p "${WHITE_TEXT}${BOLD_TEXT}⌨️ Please enter the REGION: ${RESET_FORMAT}" REGION
    if [ -z "$REGION" ]; then
      echo "${RED_TEXT}${BOLD_TEXT}🚫 Region cannot be empty. Please provide a valid region.${RESET_FORMAT}"
    fi
  done
fi

export REGION
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Region set to: $REGION${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🆔 Fetching your Google Cloud Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project ID identified as: $PROJECT_ID${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Configuring default compute region to $REGION...${RESET_FORMAT}"
gcloud config set compute/region $REGION
echo "${GREEN_TEXT}${BOLD_TEXT}👍 Default compute region configured.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛠️ Enabling necessary Google Cloud services. This might take a moment...${RESET_FORMAT}"
gcloud services enable \
container.googleapis.com \
clouddeploy.googleapis.com \
artifactregistry.googleapis.com \
cloudbuild.googleapis.com \
clouddeploy.googleapis.com
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Services enabled. Allowing changes to propagate...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ $i seconds remaining... ${RESET_FORMAT}"
  sleep 1
done
echo -e "\r${GREEN_TEXT}${BOLD_TEXT}⏳ Propagation time complete. ${RESET_FORMAT}"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🏗️ Initiating creation of GKE clusters (test, staging, prod) asynchronously...${RESET_FORMAT}"
gcloud container clusters create test --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create staging --node-locations=$ZONE --num-nodes=1  --async
gcloud container clusters create prod --node-locations=$ZONE --num-nodes=1  --async
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📋 Displaying initial list of GKE clusters and their statuses...${RESET_FORMAT}"
gcloud container clusters list --format="csv(name,status)"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📦 Creating Artifact Registry repository 'web-app' for Docker images...${RESET_FORMAT}"
gcloud artifacts repositories create web-app \
--description="Image registry for tutorial web app" \
--repository-format=docker \
--location=$REGION
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Artifact Registry repository created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚚 Preparing project files: Navigating to home, cloning repository, and checking out specific version...${RESET_FORMAT}"
cd ~/
git clone https://github.com/GoogleCloudPlatform/cloud-deploy-tutorials.git
cd cloud-deploy-tutorials
git checkout c3cae80 --quiet
cd tutorials/base
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Project files prepared.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Skaffold configuration from template...${RESET_FORMAT}"
envsubst < clouddeploy-config/skaffold.yaml.template > web/skaffold.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Skaffold configuration generated. Displaying content:${RESET_FORMAT}"
cat web/skaffold.yaml
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🧱 Building the application using Skaffold. This may take some time...${RESET_FORMAT}"
cd web
skaffold build --interactive=false \
--default-repo $REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--file-output artifacts.json
cd ..
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Application build complete. Artifacts metadata saved to artifacts.json.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🖼️ Listing Docker images in the Artifact Registry repository...${RESET_FORMAT}"
gcloud artifacts docker images list \
$REGION-docker.pkg.dev/$PROJECT_ID/web-app \
--include-tags \
--format yaml
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⚙️ Configuring default Cloud Deploy region to $REGION...${RESET_FORMAT}"
gcloud config set deploy/region $REGION
echo "${GREEN_TEXT}${BOLD_TEXT}👍 Cloud Deploy region configured.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📜 Setting up the Cloud Deploy delivery pipeline by copying and applying configuration...${RESET_FORMAT}"
cp clouddeploy-config/delivery-pipeline.yaml.template clouddeploy-config/delivery-pipeline.yaml
gcloud beta deploy apply --file=clouddeploy-config/delivery-pipeline.yaml
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Delivery pipeline configuration applied.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📄 Describing the 'web-app' delivery pipeline details...${RESET_FORMAT}"
gcloud beta deploy delivery-pipelines describe web-app
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Monitoring GKE cluster statuses. Waiting for all clusters to be in 'RUNNING' state...${RESET_FORMAT}"
while true; do
  cluster_statuses=$(gcloud container clusters list --format="csv(name,status)" | tail -n +2)
  all_running=true
  echo "${YELLOW_TEXT}${BOLD_TEXT}🔄 Checking cluster statuses...${RESET_FORMAT}"
  while IFS=, read -r cluster_name cluster_status; do
    echo "${CYAN_TEXT}Cluster: ${cluster_name}, Status: ${cluster_status}${RESET_FORMAT}"
    if [[ "$cluster_status" != "RUNNING" ]]; then
      all_running=false
    fi
  done <<< "$cluster_statuses"

  if $all_running; then
    echo "${GREEN_TEXT}${BOLD_TEXT}🎉 All clusters are now in RUNNING state!${RESET_FORMAT}"
    break
  fi

  echo "${YELLOW_TEXT}${BOLD_TEXT}🕒 Not all clusters are running yet. Re-checking in 10 seconds...${RESET_FORMAT}"
  for i in $(seq 10 -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ $i seconds remaining before next check... ${RESET_FORMAT}"
    sleep 1
  done
  echo -e "\r${YELLOW_TEXT}${BOLD_TEXT}⏳ Re-checking now...                               ${RESET_FORMAT}" # Extra spaces to clear the line
done
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔑 Fetching GKE cluster credentials and renaming kubectl contexts for easier access...${RESET_FORMAT}"
CONTEXTS=("test" "staging" "prod")
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${CYAN_TEXT}${BOLD_TEXT}Processing context: ${CONTEXT}...${RESET_FORMAT}"
    gcloud container clusters get-credentials ${CONTEXT} --region ${REGION}
    kubectl config rename-context gke_${PROJECT_ID}_${REGION}_${CONTEXT} ${CONTEXT}
done
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Credentials fetched and contexts renamed.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🏠 Applying Kubernetes namespace 'web-app' to all contexts...${RESET_FORMAT}"
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${CYAN_TEXT}${BOLD_TEXT}Applying namespace to context: ${CONTEXT}...${RESET_FORMAT}"
    kubectl --context ${CONTEXT} apply -f kubernetes-config/web-app-namespace.yaml
done
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Namespace applied to all contexts.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🎯 Configuring and applying Cloud Deploy targets for each environment...${RESET_FORMAT}"
for CONTEXT in ${CONTEXTS[@]}
do
    echo "${CYAN_TEXT}${BOLD_TEXT}Processing target: ${CONTEXT}...${RESET_FORMAT}"
    envsubst < clouddeploy-config/target-$CONTEXT.yaml.template > clouddeploy-config/target-$CONTEXT.yaml
    gcloud beta deploy apply --file=clouddeploy-config/target-$CONTEXT.yaml
done
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Cloud Deploy targets configured and applied.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📋 Listing all configured Cloud Deploy targets...${RESET_FORMAT}"
gcloud beta deploy targets list
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚀 Creating a new Cloud Deploy release 'web-app-001'...${RESET_FORMAT}"
gcloud beta deploy releases create web-app-001 \
--delivery-pipeline web-app \
--build-artifacts web/artifacts.json \
--source web/
echo "${GREEN_TEXT}${BOLD_TEXT}✅ Release 'web-app-001' created.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📊 Listing rollouts for the 'web-app-001' release...${RESET_FORMAT}"
gcloud beta deploy rollouts list \
--delivery-pipeline web-app \
--release web-app-001
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for the initial rollout to 'test' target to complete...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)

  if [ "$status" == "SUCCEEDED" ]; then
    echo -e "\r${GREEN_TEXT}${BOLD_TEXT}🎉 Rollout to 'test' SUCCEEDED!                                        ${RESET_FORMAT}"
    break
  elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" ]]; then
    echo -e "\r${RED_TEXT}${BOLD_TEXT}❌ Rollout to 'test' is ${status}. Please check logs.                 ${RESET_FORMAT}"
    break 
  fi
  
  current_status_display=${status:-"UNKNOWN"}

  WAIT_DURATION=10 
  for i in $(seq $WAIT_DURATION -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ 'Test' rollout status: ${current_status_display}. $i seconds remaining... ${RESET_FORMAT}            "
    sleep 1
  done
  echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}⏳ 'Test' rollout status: ${current_status_display}. Re-checking now... ${RESET_FORMAT}            "
done
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔬 Switching to 'test' Kubernetes context and verifying deployed resources...${RESET_FORMAT}"
kubectx test
kubectl get all -n web-app
echo

echo "${BLUE_TEXT}${BOLD_TEXT}➡️ Promoting release 'web-app-001' to the 'staging' target...${RESET_FORMAT}"
gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for the rollout to 'staging' target to complete...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)

  if [ "$status" == "SUCCEEDED" ]; then
    echo -e "\r${GREEN_TEXT}${BOLD_TEXT}🎉 Rollout to 'staging' SUCCEEDED!                                        ${RESET_FORMAT}"
    break
  elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" ]]; then
    echo -e "\r${RED_TEXT}${BOLD_TEXT}❌ Rollout to 'staging' is ${status}. Please check logs.                 ${RESET_FORMAT}"
    break 
  fi
  
  current_status_display=${status:-"UNKNOWN"} 

  WAIT_DURATION=10 
  for i in $(seq $WAIT_DURATION -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ 'Staging' rollout status: ${current_status_display}. $i seconds remaining... ${RESET_FORMAT}            "
    sleep 1
  done
  echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}⏳ 'Staging' rollout status: ${current_status_display}. Re-checking now... ${RESET_FORMAT}            "
done
echo

echo "${BLUE_TEXT}${BOLD_TEXT}➡️ Promoting release 'web-app-001' to the 'prod' target (this will require approval)...${RESET_FORMAT}"
gcloud beta deploy releases promote \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for the rollout to 'prod' to reach 'PENDING_APPROVAL' state...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)

  if [ "$status" == "PENDING_APPROVAL" ]; then
    echo -e "\r${GREEN_TEXT}${BOLD_TEXT}👍 Rollout to 'prod' is now PENDING_APPROVAL!                                 ${RESET_FORMAT}"
    break
  elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" || "$status" == "SUCCEEDED" ]]; then
    echo -e "\r${RED_TEXT}${BOLD_TEXT}❌ Rollout to 'prod' is ${status} instead of PENDING_APPROVAL. Please check logs. ${RESET_FORMAT}"
  fi
  
  current_status_display=${status:-"UNKNOWN"} 

  WAIT_DURATION=10 # seconds
  for i in $(seq $WAIT_DURATION -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ 'Prod' rollout status: ${current_status_display}. Waiting for PENDING_APPROVAL. $i seconds remaining... ${RESET_FORMAT}            "
    sleep 1
  done
  echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}⏳ 'Prod' rollout status: ${current_status_display}. Re-checking now...                                           ${RESET_FORMAT}" 
done
echo

echo "${BLUE_TEXT}${BOLD_TEXT}👍 Approving the rollout 'web-app-001-to-prod-0001' for the 'prod' target...${RESET_FORMAT}"
gcloud beta deploy rollouts approve web-app-001-to-prod-0001 \
--delivery-pipeline web-app \
--release web-app-001 \
--quiet
echo

echo "${BLUE_TEXT}${BOLD_TEXT}⏳ Waiting for the rollout to 'prod' target to complete after approval...${RESET_FORMAT}"
while true; do
  status=$(gcloud beta deploy rollouts list --delivery-pipeline web-app --release web-app-001 --format="value(state)" | head -n 1)

  if [ "$status" == "SUCCEEDED" ]; then
    echo -e "\r${GREEN_TEXT}${BOLD_TEXT}🎉 Rollout to 'prod' SUCCEEDED!                                        ${RESET_FORMAT}"
    break
  elif [[ "$status" == "FAILED" || "$status" == "CANCELLED" || "$status" == "HALTED" ]]; then
    echo -e "\r${RED_TEXT}${BOLD_TEXT}❌ Rollout to 'prod' is ${status}. Please check logs.                 ${RESET_FORMAT}"
    break 
  fi
  
  current_status_display=${status:-"UNKNOWN"} 

  WAIT_DURATION=10 
  for i in $(seq $WAIT_DURATION -1 1); do
    echo -ne "${YELLOW_TEXT}${BOLD_TEXT}\r⏳ 'Prod' rollout status: ${current_status_display}. $i seconds remaining... ${RESET_FORMAT}            "
    sleep 1
  done
  echo -ne "\r${YELLOW_TEXT}${BOLD_TEXT}⏳ 'Prod' rollout status: ${current_status_display}. Re-checking now... ${RESET_FORMAT}            "
done
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔬 Switching to 'prod' Kubernetes context and verifying deployed resources...${RESET_FORMAT}"
kubectx prod
kubectl get all -n web-app
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
