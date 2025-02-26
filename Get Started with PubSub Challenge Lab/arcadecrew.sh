#!/bin/bash

# Bright Foreground Colors
BRIGHT_BLACK_TEXT=$'\033[0;90m'
BRIGHT_RED_TEXT=$'\033[0;91m'
BRIGHT_GREEN_TEXT=$'\033[0;92m'
BRIGHT_YELLOW_TEXT=$'\033[0;93m'
BRIGHT_BLUE_TEXT=$'\033[0;94m'
BRIGHT_MAGENTA_TEXT=$'\033[0;95m'
BRIGHT_CYAN_TEXT=$'\033[0;96m'
BRIGHT_WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'

# Start of the script
echo
echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

# Function to run form 1 code
run_form_1() {
    echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Running Form 1: Enabling Cloud Scheduler, creating Pub/Sub topic, subscription, and scheduler job...${RESET_FORMAT}"
    gcloud services enable cloudscheduler.googleapis.com

    gcloud pubsub topics create cloud-pubsub-topic

    gcloud pubsub subscriptions create 'cloud-pubsub-subscription' --topic=cloud-pubsub-topic

    gcloud scheduler jobs create pubsub cron-scheduler-job \
        --schedule="* * * * *" --topic=cron-job-pubsub-topic \
        --message-body="Hello World!" --location=$REGION

    gcloud pubsub subscriptions pull cron-job-pubsub-subscription --limit 5
}

# Function to run form 2 code
run_form_2() {
    echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Running Form 2: Creating Pub/Sub schema, topic, and deploying a Cloud Function...${RESET_FORMAT}"
    gcloud beta pubsub schemas create city-temp-schema \
        --type=avro \
        --definition='{
            "type": "record",
            "name": "Avro",
            "fields": [
                {
                    "name": "city",
                    "type": "string"
                },
                {
                    "name": "temperature",
                    "type": "double"
                },
                {
                    "name": "pressure",
                    "type": "int"
                },
                {
                    "name": "time_position",
                    "type": "string"
                }
            ]
        }'

    gcloud pubsub topics create temp-topic \
        --message-encoding=JSON \
        --message-storage-policy-allowed-regions=$REGION \
        --schema=projects/$DEVSHELL_PROJECT_ID/schemas/temperature-schema

    mkdir arcadecrew && cd $_

    cat >index.js <<'EOF_END'
        /**
        * Triggered from a message on a Cloud Pub/Sub topic.
        *
        * @param {!Object} event Event payload.
        * @param {!Object} context Metadata for the event.
        */
        exports.helloPubSub = (event, context) => {
        const message = event.data
            ? Buffer.from(event.data, 'base64').toString()
            : 'Hello, World';
        console.log(message);
        };
EOF_END

    cat >package.json <<'EOF_END'
        {
        "name": "sample-pubsub",
        "version": "0.0.1",
        "dependencies": {
            "@google-cloud/pubsub": "^0.18.0"
        }
        }
EOF_END

    deploy_function() {
        gcloud functions deploy gcf-pubsub \
            --trigger-topic=gcf-topic \
            --runtime=nodejs20 \
            --no-gen2 \
            --entry-point=helloPubSub \
            --source=. \
            --region=$REGION
    }

    deploy_success=false

    while [ "$deploy_success" = false ]; do
        if deploy_function; then
            echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Function deployed successfully...${RESET_FORMAT}"
            deploy_success=true
        else
            echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}Waiting for Cloud Function to be deployed...${RESET_FORMAT}"
            sleep 20
        fi
    done
}

# Function to run form 3 code
run_form_3() {
    echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Running Form 3: Creating Pub/Sub subscription, publishing a message, and creating a snapshot...${RESET_FORMAT}"
    gcloud pubsub subscriptions create pubsub-subscription-message --topic gcloud-pubsub-topic

    gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello World"

    sleep 10

    gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5

    gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription
}

# User input for REGION
echo "${BRIGHT_YELLOW_TEXT}${BOLD_TEXT}"
read -p "Enter REGION: " REGION
echo "${RESET_FORMAT}${BOLD_TEXT}"

# User input for Form number
echo "${BRIGHT_BLUE_TEXT}${BOLD_TEXT}"
read -p "Enter Form number (1, 2, or 3): " form_number
echo "${RESET_FORMAT}${BOLD_TEXT}"

# Execute the appropriate function based on the selected form number
case $form_number in
1) run_form_1 ;;
2) run_form_2 ;;
3) run_form_3 ;;
*) echo "${BRIGHT_RED_TEXT}${BOLD_TEXT}Invalid form number. Please enter 1, 2, or 3.${RESET_FORMAT}" ;;
esac
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BRIGHT_RED_TEXT}${BOLD_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${BRIGHT_RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BRIGHT_BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
