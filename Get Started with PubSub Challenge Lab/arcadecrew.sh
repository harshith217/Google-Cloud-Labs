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
    # Function to display error messages
    error_message() {
        echo "${BRIGHT_RED_TEXT}${BOLD_TEXT}ERROR: $1${RESET_FORMAT}"
        exit 1
    }

# Function to display success messages
    success_message() {
        echo "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}SUCCESS: $1${RESET_FORMAT}"
    }

    # Function to display informational messages
    info_message() {
        echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}INFO: $1${RESET_FORMAT}"
    }

# Function to verify command execution
    verify_command() {
        if [ $? -eq 0 ]; then
            success_message "$1"
        else
            error_message "$2"
        fi
    }

# Step 1: Set up Cloud Pub/Sub
    setup_pubsub() {
        info_message "Starting Task 1: Setting up Cloud Pub/Sub..."

    # Create a Cloud Pub/Sub topic
        info_message "Creating Pub/Sub topic 'cloud-pubsub-topic'..."
        gcloud pubsub topics create cloud-pubsub-topic
        verify_command "Pub/Sub topic 'cloud-pubsub-topic' created successfully." "Failed to create Pub/Sub topic."

    # Create a Cloud Pub/Sub subscription
        info_message "Creating Pub/Sub subscription 'cloud-pubsub-subscription'..."
        gcloud pubsub subscriptions create cloud-pubsub-subscription --topic=cloud-pubsub-topic
        verify_command "Pub/Sub subscription 'cloud-pubsub-subscription' created successfully." "Failed to create Pub/Sub subscription."

        success_message "Task 1 completed: Cloud Pub/Sub setup is done."
    }

# Step 2: Create a Cloud Scheduler job
    create_scheduler_job() {
        info_message "Starting Task 2: Creating a Cloud Scheduler job..."

    # Check if the Cloud Scheduler job already exists
        info_message "Checking if Cloud Scheduler job 'cron-scheduler-job' already exists..."
        if gcloud scheduler jobs describe cron-scheduler-job --location="$REGION" >/dev/null 2>&1; then
            info_message "Cloud Scheduler job 'cron-scheduler-job' already exists. Deleting it..."
            gcloud scheduler jobs delete cron-scheduler-job --location="$REGION"
            verify_command "Cloud Scheduler job 'cron-scheduler-job' deleted successfully." "Failed to delete Cloud Scheduler job."
        fi

    # Create a Cloud Scheduler job
        info_message "Creating Cloud Scheduler job 'cron-scheduler-job'..."
        gcloud scheduler jobs create pubsub cron-scheduler-job \
            --schedule="* * * * *" \
            --topic=cloud-pubsub-topic \
            --message-body="Hello World!" \
            --location="$REGION"
        verify_command "Cloud Scheduler job 'cron-scheduler-job' created successfully." "Failed to create Cloud Scheduler job."

        success_message "Task 2 completed: Cloud Scheduler job is created."
    }

# Step 3: Verify the results in Cloud Pub/Sub
    verify_pubsub_results() {
        info_message "Starting Task 3: Verifying results in Cloud Pub/Sub..."

    # Pull messages from the subscription
        info_message "Pulling messages from subscription 'cloud-pubsub-subscription'..."
        gcloud pubsub subscriptions pull cloud-pubsub-subscription --limit=5
        verify_command "Messages pulled successfully from subscription 'cloud-pubsub-subscription'." "Failed to pull messages from subscription."

        success_message "Task 3 completed: Verification of Pub/Sub messages is done."
    }

# Main script execution
    main() {
        echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Starting the lab automation script...${RESET_FORMAT}"

    # Task 1: Set up Cloud Pub/Sub
        setup_pubsub

    # Task 2: Create a Cloud Scheduler job
        create_scheduler_job

    # Task 3: Verify the results in Cloud Pub/Sub
        verify_pubsub_results

        echo "${BRIGHT_MAGENTA_TEXT}${BOLD_TEXT}Lab automation script completed successfully!${RESET_FORMAT}"
    }

# Execute the main function
    main
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
            echo "${BRIGHT_CYAN_TEXT}${BOLD_TEXT}Meanwhile, make sure to subscribe to Arcade Crew: https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
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
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
# Completion message
echo -e "${BRIGHT_GREEN_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${BRIGHT_RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BRIGHT_BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
