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

echo "${GREEN_TEXT}${BOLD_TEXT}🛠️  Fetching your current GCP Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)

echo
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION for the first function: ${RESET_FORMAT}"
read REGION1
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the NAME for the first HTTP function: ${RESET_FORMAT}"
read FUNCTION_NAME1
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the REGION for the second function: ${RESET_FORMAT}"
read REGION2
echo -n "${YELLOW_TEXT}${BOLD_TEXT}Enter the NAME for the second Pub/Sub function: ${RESET_FORMAT}"
read FUNCTION_NAME2

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🔍 Review the configuration you provided:${RESET_FORMAT}"
echo "${YELLOW_TEXT}REGION1: ${WHITE_TEXT}${REGION1}${RESET_FORMAT}"
echo "${YELLOW_TEXT}FUNCTION_NAME1: ${WHITE_TEXT}${FUNCTION_NAME1}${RESET_FORMAT}"
echo "${YELLOW_TEXT}REGION2: ${WHITE_TEXT}${REGION2}${RESET_FORMAT}"
echo "${YELLOW_TEXT}FUNCTION_NAME2: ${WHITE_TEXT}${FUNCTION_NAME2}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📁 Creating directory for the Go HTTP Cloud Function source code...${RESET_FORMAT}"
mkdir -p cloud-function-http-go

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Go source file (main.go) for the HTTP Cloud Function...${RESET_FORMAT}"
cat > cloud-function-http-go/main.go <<EOF
package p

import (
  "net/http"
)

func HelloHTTP(w http.ResponseWriter, r *http.Request) {
  w.Write([]byte("Hello from Go HTTP Cloud Function!"))
}
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Go module file (go.mod) for the HTTP Cloud Function...${RESET_FORMAT}"
cat > cloud-function-http-go/go.mod <<EOF
module cloudfunction

go 1.21
EOF

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Deploying the first Go HTTP Cloud Function (${FUNCTION_NAME1})... This might take a few minutes. ⏳${RESET_FORMAT}"
gcloud functions deploy ${FUNCTION_NAME1} \
  --gen2 \
  --runtime=go121 \
  --region=${REGION1} \
  --source=cloud-function-http-go \
  --entry-point=HelloHTTP \
  --trigger-http \
  --max-instances=5 \
  --allow-unauthenticated

echo
echo "${BLUE_TEXT}${BOLD_TEXT}📁 Creating directory for the Go Pub/Sub Cloud Function source code...${RESET_FORMAT}"
mkdir -p cloud-function-pubsub-go

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Go source file (main.go) for the Pub/Sub Cloud Function...${RESET_FORMAT}"
cat > cloud-function-pubsub-go/main.go <<EOF
package p

import (
  "context"
  "log"
)

type PubSubMessage struct {
  Data []byte \`json:"data"\`
}

func HelloPubSub(ctx context.Context, m PubSubMessage) error {
  log.Printf("Hello, %s!", string(m.Data))
  return nil
}
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}📝 Generating Go module file (go.mod) for the Pub/Sub Cloud Function...${RESET_FORMAT}"
cat > cloud-function-pubsub-go/go.mod <<EOF
module cloudfunction

go 1.21
EOF

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🚀 Deploying the second Go Pub/Sub Cloud Function (${FUNCTION_NAME2})... This might take a few minutes. ⏳${RESET_FORMAT}"
gcloud functions deploy ${FUNCTION_NAME2} \
  --gen2 \
  --runtime=go121 \
  --region=${REGION2} \
  --source=cloud-function-pubsub-go \
  --entry-point=HelloPubSub \
  --trigger-topic=cf-pubsub \
  --max-instances=5

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🏠 Navigating back to the home directory...${RESET_FORMAT}"
cd ~

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
