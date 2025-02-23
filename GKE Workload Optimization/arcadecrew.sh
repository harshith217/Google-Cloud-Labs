#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Start of the script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Prompt user to set the zone
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 1: Set the compute zone.${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}Please Enter ZONE:${RESET_FORMAT}"
read -p "Zone: " ZONE
export ZONE=$ZONE

# Set the compute zone
gcloud config set compute/zone $ZONE

# Create a GKE cluster
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 2: Creating a GKE cluster with 3 nodes...${RESET_FORMAT}"
gcloud container clusters create test-cluster --num-nodes=3 --enable-ip-alias

# Create the gb-frontend pod
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Step 3: Creating the gb-frontend pod...${RESET_FORMAT}"
cat << EOF > gb_frontend_pod.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: gb-frontend
  name: gb-frontend
spec:
    containers:
    - name: gb-frontend
      image: gcr.io/google-samples/gb-frontend-amd64:v5
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
      ports:
      - containerPort: 80
EOF

kubectl apply -f gb_frontend_pod.yaml

# Create the gb-frontend ClusterIP service
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 4: Creating the gb-frontend ClusterIP service...${RESET_FORMAT}"
cat << EOF > gb_frontend_cluster_ip.yaml
apiVersion: v1
kind: Service
metadata:
  name: gb-frontend-svc
  annotations:
    cloud.google.com/neg: '{"ingress": true}'
spec:
  type: ClusterIP
  selector:
    app: gb-frontend
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
EOF

kubectl apply -f gb_frontend_cluster_ip.yaml

# Create the gb-frontend Ingress
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 5: Creating the gb-frontend Ingress...${RESET_FORMAT}"
cat << EOF > gb_frontend_ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gb-frontend-ingress
spec:
  defaultBackend:
    service:
      name: gb-frontend-svc
      port:
        number: 80
EOF

kubectl apply -f gb_frontend_ingress.yaml

# Wait for 70 seconds
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Waiting for 70 seconds to allow resources to stabilize...${RESET_FORMAT}"
sleep 70

# Get backend service health
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 6: Checking backend service health...${RESET_FORMAT}"
BACKEND_SERVICE=$(gcloud compute backend-services list | grep NAME | cut -d ' ' -f2)
gcloud compute backend-services get-health $BACKEND_SERVICE --global

# Get Ingress details
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Step 7: Retrieving Ingress details...${RESET_FORMAT}"
kubectl get ingress gb-frontend-ingress

# Prompt user to check the score for Task 1
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}NOW${RESET_FORMAT} ${WHITE_TEXT}${BOLD_TEXT}Check The Score${RESET_FORMAT} ${GREEN_TEXT}${BOLD_TEXT}For Task 1.${RESET_FORMAT}"

# Replace sleep 120 with a yes/no prompt
while true; do
    read -p "${MAGENTA_TEXT}Have you checked the progress for Task 1? (Y/N): ${RESET_FORMAT}" user_input
    case $user_input in
        [Yy]|[Yy][Ee][Ss])
            echo "${GREEN_TEXT}Proceeding to the next step...${RESET_FORMAT}"
            break
            ;;
        [Nn]|[Nn][Oo])
            echo "${RED_TEXT}Please check the progress for Task 1 before proceeding.${RESET_FORMAT}"
            ;;
        *)
            echo "${RED_TEXT}Invalid input. Please enter Y or N.${RESET_FORMAT}"
            ;;
    esac
done

# Copy Locust image and build
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 8: Copying Locust image and building...${RESET_FORMAT}"
gsutil -m cp -r gs://spls/gsp769/locust-image .
gcloud builds submit --tag gcr.io/${GOOGLE_CLOUD_PROJECT}/locust-tasks:latest locust-image

# List container images
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 9: Listing container images...${RESET_FORMAT}"
gcloud container images list

# Deploy Locust
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 10: Deploying Locust...${RESET_FORMAT}"
gsutil cp gs://spls/gsp769/locust_deploy_v2.yaml .
sed 's/${GOOGLE_CLOUD_PROJECT}/'$GOOGLE_CLOUD_PROJECT'/g' locust_deploy_v2.yaml | kubectl apply -f -

# Wait for 70 seconds
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Waiting for 70 seconds to allow Locust deployment to stabilize...${RESET_FORMAT}"
sleep 70

# Create liveness-demo pod
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Step 11: Creating liveness-demo pod...${RESET_FORMAT}"
cat << EOF > liveness-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: liveness-probe
  name: liveness-demo-pod
spec:
  containers:
  - name: liveness-demo-pod
    image: centos
    args:
    - /bin/sh
    - -c
    - touch /tmp/alive; sleep infinity
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/alive
      initialDelaySeconds: 5
      periodSeconds: 10
EOF

kubectl apply -f liveness-demo.yaml

# Describe liveness-demo pod
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 12: Describing liveness-demo pod...${RESET_FORMAT}"
kubectl describe pod liveness-demo-pod

# Remove the alive file to trigger liveness probe
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 13: Removing /tmp/alive to trigger liveness probe...${RESET_FORMAT}"
kubectl exec liveness-demo-pod -- rm /tmp/alive

# Describe liveness-demo pod again
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 14: Describing liveness-demo pod after triggering liveness probe...${RESET_FORMAT}"
kubectl describe pod liveness-demo-pod

# Create readiness-demo pod
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 15: Creating readiness-demo pod...${RESET_FORMAT}"
cat << EOF > readiness-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    demo: readiness-probe
  name: readiness-demo-pod
spec:
  containers:
  - name: readiness-demo-pod
    image: nginx
    ports:
    - containerPort: 80
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/healthz
      initialDelaySeconds: 5
      periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: readiness-demo-svc
  labels:
    demo: readiness-probe
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  selector:
    demo: readiness-probe
EOF

kubectl apply -f readiness-demo.yaml

# Wait for 70 seconds
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Waiting for 70 seconds to allow readiness-demo pod to stabilize...${RESET_FORMAT}"
sleep 70

# Create healthz file to pass readiness probe
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 16: Creating /tmp/healthz to pass readiness probe...${RESET_FORMAT}"
kubectl exec readiness-demo-pod -- touch /tmp/healthz

# Describe readiness-demo pod
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 17: Describing readiness-demo pod...${RESET_FORMAT}"
kubectl describe pod readiness-demo-pod | grep ^Conditions -A 5

# Delete gb-frontend pod
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Step 18: Deleting gb-frontend pod...${RESET_FORMAT}"
kubectl delete pod gb-frontend

# Create gb-frontend deployment
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 19: Creating gb-frontend deployment...${RESET_FORMAT}"
cat << EOF > gb_frontend_deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gb-frontend
  labels:
    run: gb-frontend
spec:
  replicas: 5
  selector:
    matchLabels:
      run: gb-frontend
  template:
    metadata:
      labels:
        run: gb-frontend
    spec:
      containers:
        - name: gb-frontend
          image: gcr.io/google-samples/gb-frontend-amd64:v5
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
          ports:
            - containerPort: 80
              protocol: TCP
EOF

kubectl apply -f gb_frontend_deployment.yaml
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
