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

echo "${GREEN_TEXT}${BOLD_TEXT}✨ Setting up your Google Cloud Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID set to: ${WHITE_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🗺️ Determining the default compute zone for your project...${RESET_FORMAT}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo "${CYAN_TEXT}${BOLD_TEXT}Default Compute Zone set to: ${WHITE_TEXT}$ZONE${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🏗️ Creating a new Google Kubernetes Engine (GKE) cluster named 'gmp-cluster' with 3 nodes in the zone '${WHITE_TEXT}$ZONE${YELLOW_TEXT}${BOLD_TEXT}'.${RESET_FORMAT}"
gcloud container clusters create gmp-cluster --num-nodes=3 --zone=$ZONE
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🔑 With the cluster ready, let's fetch its credentials. This allows kubectl to communicate with your new GKE cluster.${RESET_FORMAT}"
gcloud container clusters get-credentials gmp-cluster --zone=$ZONE
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🏷️ We'll create a dedicated namespace called 'gmp-test' in your cluster. Namespaces help organize resources within Kubernetes.${RESET_FORMAT}"
kubectl create ns gmp-test
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🚀 Time to deploy an example application! This will be deployed into the 'gmp-test' namespace.${RESET_FORMAT}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.4.3-gke.0/examples/example-app.yaml
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📊 Next up, we're deploying the Prometheus configuration into the 'gmp-test' namespace to monitor our application.${RESET_FORMAT}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.4.3-gke.0/examples/prometheus.yaml
echo

echo "${CYAN_TEXT}${BOLD_TEXT}⏳ Let's give the deployed resources some time to initialize. We'll pause for 150 seconds. ${RESET_FORMAT}"
for i in $(seq 150 -1 1); do
  echo -ne "${CYAN_TEXT}${BOLD_TEXT}⏳ ${WHITE_TEXT} $i seconds remaining...${RESET_FORMAT}\r"
  sleep 1
done
echo -ne "\n"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 After the wait, let's check the status of our pods in the 'gmp-test' namespace to ensure everything is running smoothly.${RESET_FORMAT}"
kubectl -n gmp-test get pod
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🌐 Now, we'll deploy a frontend application. We're fetching its configuration, substituting your Project ID ('${WHITE_TEXT}$PROJECT_ID${GREEN_TEXT}${BOLD_TEXT}'), and then applying it to the 'gmp-test' namespace.${RESET_FORMAT}"
curl https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.4.3-gke.0/examples/frontend.yaml |
sed "s/\$PROJECT_ID/$PROJECT_ID/" | kubectl apply -n gmp-test -f -
echo

echo "${CYAN_TEXT}${BOLD_TEXT}🔗 To access the frontend, we'll set up port forwarding. This will make the 'frontend' service in 'gmp-test' accessible on your local port 9090.${RESET_FORMAT}"
kubectl -n gmp-test port-forward svc/frontend 9090 &
echo
echo "${BLUE_TEXT}${BOLD_TEXT}ℹ️ Port forwarding for the frontend service has been started in the background. You can access it at http://localhost:9090 ${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📦 We need some additional configurations for Grafana. Let's clone the 'kube-prometheus' repository.${RESET_FORMAT}"
git clone https://github.com/prometheus-operator/kube-prometheus.git
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📁 Navigating into the 'kube-prometheus' directory to access Grafana configurations...${RESET_FORMAT}"
cd kube-prometheus
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🎨 Finally, we'll apply the Grafana configuration to visualize our metrics. This will also be deployed in the 'gmp-test' namespace.${RESET_FORMAT}"
kubectl -n gmp-test apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/prometheus-engine/v0.4.3-gke.0/examples/grafana.yaml
echo

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

