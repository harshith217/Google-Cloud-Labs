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

# Instructions for the user
echo "${GREEN_TEXT}${BOLD_TEXT}Step 1: Fetching the default region and zone from your GCP project...${RESET_FORMAT}"
echo

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

PROJECT_ID=`gcloud config get-value project`

echo "${GREEN_TEXT}${BOLD_TEXT}Step 2: Creating a GKE cluster named 'cluster-1'...${RESET_FORMAT}"
echo "${CYAN_TEXT}- Zone: us-central1-c${RESET_FORMAT}"
echo "${CYAN_TEXT}- Machine type: e2-medium${RESET_FORMAT}"
echo "${CYAN_TEXT}- Disk size: 100GB${RESET_FORMAT}"
echo "${CYAN_TEXT}- Number of nodes: 3${RESET_FORMAT}"
echo

gcloud beta container --project "$PROJECT_ID" clusters create "cluster-1" --zone "us-central1-c" --tier "standard" --no-enable-basic-auth --cluster-version "latest" --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM,STORAGE,POD,DEPLOYMENT,STATEFULSET,DAEMONSET,HPA,CADVISOR,KUBELET --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/us-central1/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --enable-ip-access --security-posture=standard --workload-vulnerability-scanning=disabled --no-enable-master-authorized-networks --no-enable-google-cloud-access --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --binauthz-evaluation-mode=DISABLED --enable-managed-prometheus --enable-shielded-nodes --node-locations "us-central1-c"

echo "${GREEN_TEXT}${BOLD_TEXT}Step 3: Creating a Kubernetes secret for MySQL...${RESET_FORMAT}"
echo

kubectl create secret generic mysql-secrets --from-literal=ROOT_PASSWORD="password"

echo "${GREEN_TEXT}${BOLD_TEXT}Step 4: Setting up MySQL deployment on GKE...${RESET_FORMAT}"
echo

mkdir mysql-gke
cd mysql-gke

cat > volume.yaml <<EOF_END
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-data-disk
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF_END

cat > deployment.yaml <<EOF_END
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-deployment
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          ports:
            - containerPort: 3306
          volumeMounts:
            - mountPath: "/var/lib/mysql"
              subPath: "mysql"
              name: mysql-data
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secrets
                  key: ROOT_PASSWORD
            - name: MYSQL_USER
              value: testuser
            - name: MYSQL_PASSWORD
              value: password
      volumes:
        - name: mysql-data
          persistentVolumeClaim:
            claimName: mysql-data-disk
EOF_END

cat > service.yaml <<EOF_END
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
EOF_END

echo "${GREEN_TEXT}${BOLD_TEXT}Step 5: Applying the YAML files to deploy MySQL on GKE...${RESET_FORMAT}"
echo

kubectl apply -f volume.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

echo "${GREEN_TEXT}${BOLD_TEXT}Step 6: Setting up Helm and deploying MySQL using Bitnami Helm chart...${RESET_FORMAT}"
echo

helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

helm install mydb bitnami/mysql

echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo