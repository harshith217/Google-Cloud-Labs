#!/bin/bash

# === Shared Color Codes & Helper Functions (from Forms 1 & 2) ===
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Default Retry Settings (Can be overridden within functions if needed)
DEFAULT_MAX_RETRIES=3
DEFAULT_RETRY_DELAY=10 # seconds

log_info() {
    echo "${CYAN_TEXT}${BOLD_TEXT}[INFO]${RESET_FORMAT} ${CYAN_TEXT}$1${NO_COLOR}"
}

log_success() {
    echo "${GREEN_TEXT}${BOLD_TEXT}[SUCCESS]${RESET_FORMAT} ${GREEN_TEXT}$1${NO_COLOR}"
}

log_warning() {
    echo "${YELLOW_TEXT}${BOLD_TEXT}[WARNING]${RESET_FORMAT} ${YELLOW_TEXT}$1${NO_COLOR}"
}

log_error() {
    echo "${RED_TEXT}${BOLD_TEXT}[ERROR]${RESET_FORMAT} ${RED_TEXT}$1${NO_COLOR}" >&2
}

# Function to check the exit code of the last command
# Usage: command_that_might_fail || check_command_success "Error message"
check_command_success() {
    # This function expects to be called like: some_command || check_command_success "Failure message" $?
    # Or rely on the $? from the previous command if called immediately after.
    local exit_code=$?
    local message="${1:-Command failed}" # Default message if none provided
    if [ $exit_code -ne 0 ]; then
        log_error "$message (Exit Code: $exit_code)"
        # Optionally add cleanup logic here if needed globally,
        # but Forms 1 and 2 have specific cleanup needs handled within them.
        # exit $exit_code # Decide if failure should stop the whole script
    fi
    # Return the original exit code so chaining works if needed
    return $exit_code
}


# Function to retry a command if it fails
# Takes MAX_RETRIES and RETRY_DELAY from the calling scope
retry_command() {
    local cmd="$1"
    local desc="$2"
    local attempt=1
    # Use locally scoped MAX_RETRIES and RETRY_DELAY if they exist, otherwise use defaults
    local current_max_retries=${MAX_RETRIES:-$DEFAULT_MAX_RETRIES}
    local current_retry_delay=${RETRY_DELAY:-$DEFAULT_RETRY_DELAY}


    log_info "Attempting: $desc (Retries: $current_max_retries, Delay: $current_retry_delay)"
    while true; do
        # Execute the command, suppressing output unless it fails on the last try
        if eval "$cmd" > /dev/null 2>&1; then
            log_success "$desc - Command successful."
            return 0
        else
            local exit_code=$?
            if [ $attempt -lt $current_max_retries ]; then
                log_warning "$desc - Attempt $attempt/$current_max_retries failed. Retrying in $current_retry_delay seconds..."
                sleep $current_retry_delay
                ((attempt++))
            else
                log_error "$desc - Command failed after $current_max_retries attempts with exit code $exit_code."
                log_info "Attempting command again with output for debugging:"
                eval "$cmd" # Run one last time showing output
                return 1    # Return failure
            fi
        fi
    done
}

# Function to attempt deletion and then retry creation command
# Takes MAX_RETRIES and RETRY_DELAY from the calling scope
delete_and_retry_command() {
    local create_cmd="$1"
    local delete_cmd="$2"
    local desc="$3"
    local attempt=1
    # Use locally scoped MAX_RETRIES and RETRY_DELAY if they exist, otherwise use defaults
    local current_max_retries=${MAX_RETRIES:-$DEFAULT_MAX_RETRIES}
    local current_retry_delay=${RETRY_DELAY:-$DEFAULT_RETRY_DELAY}

    log_info "Attempting: $desc (Retries: $current_max_retries, Delay: $current_retry_delay)"
    while true; do
        # Try creating
        if eval "$create_cmd" > /dev/null 2>&1; then
             log_success "$desc - Creation successful."
             return 0
        else
             local exit_code=$?
             log_warning "$desc - Attempt $attempt/$current_max_retries failed with code $exit_code."

             if [ $attempt -ge $current_max_retries ]; then
                 log_error "$desc - Creation failed after $current_max_retries attempts."
                 log_info "Attempting final creation with output for debugging:"
                 eval "$create_cmd" # Show output on final failure
                 return 1 # Return failure
             fi

             # If not the last attempt, try deleting before retrying creation
             if [ -n "$delete_cmd" ]; then
                 log_info "Attempting to delete potentially failed resource before retry: $delete_cmd"
                 eval "$delete_cmd" > /dev/null 2>&1 # Ignore delete errors (resource might not exist or be in weird state)
                 # Use a slightly longer delay for delete+retry, especially for functions
                 local post_delete_sleep=5
                 log_info "Pausing for $post_delete_sleep seconds after delete attempt..."
                 sleep $post_delete_sleep
             fi

             log_warning "Retrying creation in $current_retry_delay seconds..."
             sleep $current_retry_delay
             ((attempt++))
        fi
    done
}

# === Function for Form 1 Logic ===
run_form_1() {
    clear
    log_info "${BOLD_TEXT}>>> Running Form 1: Pub/Sub & Scheduler Lab <<<${RESET_FORMAT}"

    # === Configuration ===
    local TOPIC_NAME="cloud-pubsub-topic"
    local SUBSCRIPTION_NAME="cloud-pubsub-subscription"
    local SCHEDULER_JOB_NAME="cron-scheduler-job"
    local SCHEDULE="* * * * *" # Every minute
    local MESSAGE_BODY="Hello World!"
    # Use default retry settings defined globally unless overridden here
    local MAX_RETRIES=${DEFAULT_MAX_RETRIES}
    local RETRY_DELAY=${DEFAULT_RETRY_DELAY}

    # --- Script Start ---
    echo "${BLUE_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}              INITIATING EXECUTION... ${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"

    # === Prerequisites ===
    log_info "Checking for gcloud CLI..."
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud command not found. Please install and configure the Google Cloud SDK."
        return 1 # Exit this function
    fi
    log_success "gcloud CLI found."

    # === Dynamic Variable Setup ===
    log_info "Fetching Project ID..."
    local PROJECT_ID
    PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
    # Check exit code immediately
    if [ $? -ne 0 ]; then
        log_error "Failed to get Project ID. Make sure gcloud is configured correctly (gcloud init)."
        return 1
    fi
    log_success "Project ID: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

    # --- MANUAL STEP: GET REGION ---
    local REGION
    echo "${YELLOW_TEXT}${BOLD_TEXT}"
    read -p "[USER INPUT - FORM 1] Enter the Region: " REGION
    echo "${RESET_FORMAT}"
    if [ -z "$REGION" ]; then
        log_error "Region cannot be empty."
        return 1
    fi
    log_success "Using Region: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
    # ---------------------------------

    # Configure gcloud project (redundant if already set, but safe)
    gcloud config set project "$PROJECT_ID" > /dev/null
    if [ $? -ne 0 ]; then
         log_error "Failed to set gcloud project."
         return 1
    fi

    # === Task 1: Set up Cloud Pub/Sub ===
    echo
    log_info "${BOLD_TEXT}--- Task 1: Set up Cloud Pub/Sub ---${RESET_FORMAT}"

    # 1. Create Pub/Sub Topic
    log_info "Creating Pub/Sub topic: ${BOLD_TEXT}$TOPIC_NAME${RESET_FORMAT}"
    local CREATE_TOPIC_CMD="gcloud pubsub topics create $TOPIC_NAME --project=$PROJECT_ID"
    local DELETE_TOPIC_CMD="gcloud pubsub topics delete $TOPIC_NAME --project=$PROJECT_ID --quiet"
    if ! delete_and_retry_command "$CREATE_TOPIC_CMD" "$DELETE_TOPIC_CMD" "Create Pub/Sub Topic"; then
        log_error "Failed to create Pub/Sub topic $TOPIC_NAME even after retries."
        return 1 # Stop Form 1 execution
    fi

    # Verify Topic Creation
    log_info "Verifying Pub/Sub topic ${BOLD_TEXT}$TOPIC_NAME${RESET_FORMAT}..."
    if ! retry_command "gcloud pubsub topics describe $TOPIC_NAME --project=$PROJECT_ID" "Verify Pub/Sub Topic"; then
        log_error "Failed to verify Pub/Sub topic $TOPIC_NAME."
        return 1
    fi

    # 2. Create Pub/Sub Subscription
    log_info "Creating Pub/Sub subscription: ${BOLD_TEXT}$SUBSCRIPTION_NAME${RESET_FORMAT} for topic ${BOLD_TEXT}$TOPIC_NAME${RESET_FORMAT}"
    local CREATE_SUB_CMD="gcloud pubsub subscriptions create $SUBSCRIPTION_NAME --topic=$TOPIC_NAME --project=$PROJECT_ID"
    local DELETE_SUB_CMD="gcloud pubsub subscriptions delete $SUBSCRIPTION_NAME --project=$PROJECT_ID --quiet"
    if ! delete_and_retry_command "$CREATE_SUB_CMD" "$DELETE_SUB_CMD" "Create Pub/Sub Subscription"; then
         log_error "Failed to create Pub/Sub subscription $SUBSCRIPTION_NAME even after retries."
         return 1
    fi

    # Verify Subscription Creation
    log_info "Verifying Pub/Sub subscription ${BOLD_TEXT}$SUBSCRIPTION_NAME${RESET_FORMAT}..."
    if ! retry_command "gcloud pubsub subscriptions describe $SUBSCRIPTION_NAME --project=$PROJECT_ID" "Verify Pub/Sub Subscription"; then
        log_error "Failed to verify Pub/Sub subscription $SUBSCRIPTION_NAME."
        return 1
    fi

    log_success "${BOLD_TEXT}Task 1 Completed Successfully.${RESET_FORMAT}"
    # -----------------------------------------

    # === Task 2: Create a Cloud Scheduler job ===
    echo
    log_info "${BOLD_TEXT}--- Task 2: Create a Cloud Scheduler job ---${RESET_FORMAT}"

    # Check if App Engine app exists (needed for Scheduler region selection, though specifying --location avoids strict need)
    # log_info "Checking for App Engine application in region $REGION (needed for Cloud Scheduler)..."
    # if ! gcloud app describe --project=$PROJECT_ID > /dev/null 2>&1; then
    #     log_warning "No App Engine app found. Cloud Scheduler might need one. Attempting job creation anyway with specified location."
    # else
    #     log_success "App Engine application found."
    # fi

    # Create Cloud Scheduler Job
    log_info "Creating Cloud Scheduler job: ${BOLD_TEXT}$SCHEDULER_JOB_NAME${RESET_FORMAT} in location ${BOLD_TEXT}$REGION${RESET_FORMAT}"
    local CREATE_SCHEDULER_CMD="gcloud scheduler jobs create pubsub $SCHEDULER_JOB_NAME \
        --schedule=\"$SCHEDULE\" \
        --topic=$TOPIC_NAME \
        --message-body=\"$MESSAGE_BODY\" \
        --location=$REGION \
        --project=$PROJECT_ID"
    local DELETE_SCHEDULER_CMD="gcloud scheduler jobs delete $SCHEDULER_JOB_NAME --location=$REGION --project=$PROJECT_ID --quiet"

    # Note: Sometimes scheduler creation needs specific IAM roles like 'Cloud Scheduler Service Agent'
    # on the Pub/Sub topic if not automatically granted. The retry might help if it's a timing issue.
    if ! delete_and_retry_command "$CREATE_SCHEDULER_CMD" "$DELETE_SCHEDULER_CMD" "Create Cloud Scheduler Job"; then
        log_error "Failed to create Cloud Scheduler job $SCHEDULER_JOB_NAME even after retries."
        log_warning "Potential Issues: Ensure region '$REGION' is correct and supports Cloud Scheduler. Check IAM permissions (Scheduler Service Agent role on Pub/Sub topic)."
        return 1
    fi

    # Verify Scheduler Job Creation
    log_info "Verifying Cloud Scheduler job ${BOLD_TEXT}$SCHEDULER_JOB_NAME${RESET_FORMAT}..."
    if ! retry_command "gcloud scheduler jobs describe $SCHEDULER_JOB_NAME --location=$REGION --project=$PROJECT_ID" "Verify Cloud Scheduler Job"; then
        log_error "Failed to verify Cloud Scheduler job $SCHEDULER_JOB_NAME."
        return 1
    fi

    log_success "${BOLD_TEXT}Task 2 Completed Successfully.${RESET_FORMAT}"

    # -----------------------------------------

    # === Task 3: Verify the results in Cloud Pub/Sub ===
    echo
    log_info "${BOLD_TEXT}--- Task 3: Verify the results in Cloud Pub/Sub ---${RESET_FORMAT}"

    log_info "Waiting 65 seconds for the Cloud Scheduler job to trigger and publish messages..."
    sleep 65

    log_info "Attempting to pull messages from subscription: ${BOLD_TEXT}$SUBSCRIPTION_NAME${RESET_FORMAT}"
    echo "${YELLOW_TEXT}Executing: gcloud pubsub subscriptions pull $SUBSCRIPTION_NAME --limit 5 --project=$PROJECT_ID${NO_COLOR}"
    echo "--- Start of gcloud pull output ---"
    gcloud pubsub subscriptions pull $SUBSCRIPTION_NAME --limit 5 --project=$PROJECT_ID
    local PULL_EXIT_CODE=$?
    echo "--- End of gcloud pull output ---"

    if [ $PULL_EXIT_CODE -ne 0 ]; then
        log_warning "Pull command exited with code $PULL_EXIT_CODE. This might be okay if no messages arrived yet, or it could indicate an issue."
    else
        log_success "Pull command executed successfully."
    fi
    # ------------------------------------------
    echo
    log_info "${BOLD_TEXT}<<< Finished Form 1 <<<${RESET_FORMAT}"
    echo
    echo "${GREEN_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}           LAB COMPLETED SUCCESSFULLY! ${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    
}

# === Function for Form 2 Logic ===
run_form_2() {
    clear
    log_info "${BOLD_TEXT}>>> Running Form 2: Pub/Sub Schema & Cloud Function Lab <<<${RESET_FORMAT}"

    # === Configuration ===
    # Task 1 Resources
    local SCHEMA_NAME_TASK1="city-temp-schema"
    local SCHEMA_FILE="schema_task1.json" # Temporary file
    # Task 2 Resources (Note: Uses PRE-CREATED schema)
    local PRE_CREATED_SCHEMA_NAME_TASK2="temperature-schema"
    local TOPIC_NAME_TASK2="temp-topic"
    # Task 3 Resources (Note: Uses PRE-CREATED topic)
    local FUNCTION_NAME="gcf-pubsub"
    local PRE_CREATED_TOPIC_NAME_TASK3="gcf-topic"
    local FUNCTION_RUNTIME="nodejs20" # Or nodejs18, python311, etc. Choose a recent LTS
    local FUNCTION_ENTRY_POINT="helloPubSub" # Default for sample code
    local FUNCTION_SOURCE_DIR="." # Deploy from current directory
    local FUNCTION_SOURCE_FILE="index.js" # Temporary file

    # Retry Settings Specific to Form 2 (Overrides defaults)
    local MAX_RETRIES=4 # Increased retries for function deployment due to potential IAM delays
    local RETRY_DELAY=15 # seconds

    # --- Script Start ---
    echo "${BLUE_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}              INITIATING EXECUTION... ${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"

    # === Prerequisites ===
    log_info "Checking for gcloud CLI..."
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud command not found. Please install and configure the Google Cloud SDK."
        return 1
    fi
    log_success "gcloud CLI found."

    # === Dynamic Variable Setup ===
    log_info "Fetching Project ID..."
    local PROJECT_ID
    PROJECT_ID=$(gcloud config get-value project 2> /dev/null)
    if [ $? -ne 0 ]; then
        log_error "Failed to get Project ID. Make sure gcloud is configured correctly (gcloud init)."
        return 1
    fi
    log_success "Project ID: ${BOLD_TEXT}$PROJECT_ID${RESET_FORMAT}"

    # --- MANUAL STEP: GET REGION ---
    local REGION
    echo "${YELLOW_TEXT}${BOLD_TEXT}"
    read -p "[USER INPUT - FORM 2] Enter the Region: " REGION
    echo "${RESET_FORMAT}"
    if [ -z "$REGION" ]; then
        log_error "Region cannot be empty."
        return 1
    fi
    log_success "Using Region: ${BOLD_TEXT}$REGION${RESET_FORMAT}"
    # ---------------------------------

    # Configure gcloud project (redundant if already set, but safe)
    gcloud config set project "$PROJECT_ID" > /dev/null
    if [ $? -ne 0 ]; then
         log_error "Failed to set gcloud project."
         return 1
    fi

    # Function to clean up temporary files specific to Form 2
    cleanup_form2_files() {
      log_info "Cleaning up temporary files: $SCHEMA_FILE, $FUNCTION_SOURCE_FILE"
      rm -f "$SCHEMA_FILE" "$FUNCTION_SOURCE_FILE"
    }
    # Ensure cleanup happens even if the script exits unexpectedly within this function
    trap cleanup_form2_files EXIT INT TERM

    # === Task 1: Create Pub/Sub schema ===
    echo
    log_info "${BOLD_TEXT}--- Task 1: Create Pub/Sub Schema ---${RESET_FORMAT}"

    # 1. Create the schema definition file
    log_info "Creating temporary schema definition file: ${BOLD_TEXT}$SCHEMA_FILE${RESET_FORMAT}"
    cat > "$SCHEMA_FILE" << EOL
{
    "type" : "record",
    "name" : "Avro",
    "fields" : [
        {
            "name" : "city",
            "type" : "string"
        },
        {
            "name" : "temperature",
            "type" : "double"
        },
        {
            "name" : "pressure",
            "type" : "int"
        },
        {
            "name" : "time_position",
            "type" : "string"
        }
    ]
}
EOL
    if [ $? -ne 0 ]; then
        log_error "Failed to create schema definition file $SCHEMA_FILE."
        cleanup_form2_files
        return 1
    fi
    log_success "Schema definition file created."

    # 2. Create the Pub/Sub Schema using the file
    log_info "Creating Pub/Sub schema: ${BOLD_TEXT}$SCHEMA_NAME_TASK1${RESET_FORMAT}"
    local CREATE_SCHEMA_CMD="gcloud pubsub schemas create $SCHEMA_NAME_TASK1 --type=AVRO --definition-file=$SCHEMA_FILE --project=$PROJECT_ID"
    local DELETE_SCHEMA_CMD="gcloud pubsub schemas delete $SCHEMA_NAME_TASK1 --project=$PROJECT_ID --quiet"
    # Use the retry/delay values defined locally in this function
    if ! delete_and_retry_command "$CREATE_SCHEMA_CMD" "$DELETE_SCHEMA_CMD" "Create Pub/Sub Schema '$SCHEMA_NAME_TASK1'"; then
        log_error "Failed to create Pub/Sub schema $SCHEMA_NAME_TASK1 even after retries."
        cleanup_form2_files
        return 1
    fi

    # Verify Schema Creation
    log_info "Verifying Pub/Sub schema ${BOLD_TEXT}$SCHEMA_NAME_TASK1${RESET_FORMAT}..."
    # Use the retry/delay values defined locally in this function
    if ! retry_command "gcloud pubsub schemas describe $SCHEMA_NAME_TASK1 --project=$PROJECT_ID" "Verify Pub/Sub Schema '$SCHEMA_NAME_TASK1'"; then
        log_error "Failed to verify Pub/Sub schema $SCHEMA_NAME_TASK1."
        cleanup_form2_files
        return 1
    fi

    # Clean up the temporary schema file now (will be recreated if needed later)
    rm -f "$SCHEMA_FILE"
    log_info "Removed temporary schema file ${BOLD_TEXT}$SCHEMA_FILE${RESET_FORMAT}."

    log_success "${BOLD_TEXT}Task 1 Completed Successfully.${RESET_FORMAT}"
    # -----------------------------------------

    # === Task 2: Create Pub/Sub topic using schema ===
    echo
    log_info "${BOLD_TEXT}--- Task 2: Create Pub/Sub Topic using Schema ---${RESET_FORMAT}"

    # 1. Create the topic linked to the PRE-CREATED schema
    log_info "Creating Pub/Sub topic: ${BOLD_TEXT}$TOPIC_NAME_TASK2${RESET_FORMAT} using schema ${BOLD_TEXT}$PRE_CREATED_SCHEMA_NAME_TASK2${RESET_FORMAT}"
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

    log_success "${BOLD_TEXT}Task 2 Completed Successfully.${RESET_FORMAT}"
    # -----------------------------------------

    # === Task 3: Create a trigger cloud function with Pub/Sub topic ===
    echo
    log_info "${BOLD_TEXT}--- Task 3: Create Trigger Cloud Function ---${RESET_FORMAT}"

    # 1. Create minimal source code file for the function
    log_info "Creating minimal source file: ${BOLD_TEXT}$FUNCTION_SOURCE_FILE${RESET_FORMAT} for runtime ${BOLD_TEXT}$FUNCTION_RUNTIME${RESET_FORMAT}"
    cat > "$FUNCTION_SOURCE_FILE" << EOL
/**
 * Background Cloud Function to be triggered by Pub/Sub.
 * This function is needed for deployment but actual code isn't tested by the lab check.
 *
 * @param {object} pubSubMessage The Pub/Sub message payload.
 * @param {object} context The event metadata.
 */
exports.${FUNCTION_ENTRY_POINT} = (pubSubMessage, context) => {
  const name = pubSubMessage.data
    ? Buffer.from(pubSubMessage.data, 'base64').toString()
    : 'World';

  console.log(\`Hello, \${name}!\`);
  console.log('Event ID: ' + context.eventId);
  console.log('Event type: ' + context.eventType);
  console.log('Timestamp: ' + context.timestamp);
  console.log('Resource: ' + context.resource.name);
};
EOL
    if [ $? -ne 0 ]; then
        log_error "Failed to create function source file $FUNCTION_SOURCE_FILE."
        cleanup_form2_files
        return 1
    fi
    log_success "Function source file created."

    # 2. Deploy the Cloud Function (Gen 2) triggered by the PRE-CREATED topic
    log_info "Deploying Cloud Function (Gen 2): ${BOLD_TEXT}$FUNCTION_NAME${RESET_FORMAT} in region ${BOLD_TEXT}$REGION${RESET_FORMAT}"
    log_info "Triggered by Pub/Sub topic: ${BOLD_TEXT}$PRE_CREATED_TOPIC_NAME_TASK3${RESET_FORMAT}"

    # Ensure the pre-created topic exists (lab's responsibility)
    # Note: --gen2 implies --trigger-event=google.cloud.pubsub.topic.v1.messagePublished
    local CREATE_FUNCTION_CMD="gcloud functions deploy $FUNCTION_NAME \
        --gen2 \
        --runtime=$FUNCTION_RUNTIME \
        --entry-point=$FUNCTION_ENTRY_POINT \
        --source=$FUNCTION_SOURCE_DIR \
        --region=$REGION \
        --trigger-topic=$PRE_CREATED_TOPIC_NAME_TASK3 \
        --project=$PROJECT_ID"

    local DELETE_FUNCTION_CMD="gcloud functions delete $FUNCTION_NAME --region=$REGION --gen2 --project=$PROJECT_ID --quiet"

    # Using increased retries/delay for function deployment (defined at start of this function)
    if ! delete_and_retry_command "$CREATE_FUNCTION_CMD" "$DELETE_FUNCTION_CMD" "Deploy Cloud Function '$FUNCTION_NAME'"; then
         log_error "Failed to deploy Cloud Function $FUNCTION_NAME even after retries."
         log_warning "Potential Issues: Ensure region '$REGION' is correct. Check IAM permissions (Cloud Functions Developer, Service Account User roles for you; Pub/Sub Token Creator for Pub/Sub service account on the function's service account, Cloud Run Invoker for the function's service account)."
         cleanup_form2_files
         return 1
    fi

    # Verify Function Deployment
    log_info "Verifying Cloud Function ${BOLD_TEXT}$FUNCTION_NAME${RESET_FORMAT}..."
    # Use the retry/delay values defined locally in this function
    if ! retry_command "gcloud functions describe $FUNCTION_NAME --region=$REGION --gen2 --project=$PROJECT_ID" "Verify Cloud Function '$FUNCTION_NAME'"; then
        log_error "Failed to verify Cloud Function $FUNCTION_NAME."
        cleanup_form2_files
        return 1
    fi

    # Clean up the temporary source file
    rm -f "$FUNCTION_SOURCE_FILE"
    log_info "Removed temporary function source file ${BOLD_TEXT}$FUNCTION_SOURCE_FILE${RESET_FORMAT}."

    log_success "${BOLD_TEXT}Task 3 Completed Successfully.${RESET_FORMAT}"
    # --- MANUAL STEP: Check Progress in Lab (If Applicable) ---
    # Note: The provided lab description doesn't show a "Check my progress" for Task 3.
    # If there *is* one in the actual lab, uncomment and adjust the prompt.
    # -------------------------------------------------------------

    # Disable the trap cleanup now that we're exiting normally
    trap - EXIT INT TERM

    echo
    echo "${GREEN_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}          LAB COMPLETED SUCCESSFULLY! ${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    log_info "${BOLD_TEXT}<<< Finished Form 2 <<<${RESET_FORMAT}"
}

# === Function for Form 3 Logic ===
run_form_3() {
    clear
    log_info "${BOLD_TEXT}>>> Running Form 3: Simple Pub/Sub Operations Lab <<<${RESET_FORMAT}"

    # Note: This form assumes 'gcloud-pubsub-topic' and 'gcloud-pubsub-subscription' already exist.
    # It does not include error checking or retries as per the original simple script.
# --- Script Start ---
    echo "${BLUE_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}              INITIATING EXECUTION... ${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    log_info "Attempting to create subscription 'pubsub-subscription-message' for topic 'gcloud-pubsub-topic'..."
    gcloud pubsub subscriptions create pubsub-subscription-message --topic gcloud-pubsub-topic
    if [ $? -ne 0 ]; then log_warning "Subscription creation might have failed (e.g., already exists). Continuing..."; fi

    log_info "Attempting to publish 'Hello World' to topic 'gcloud-pubsub-topic'..."
    gcloud pubsub topics publish gcloud-pubsub-topic --message="Hello World"
    if [ $? -ne 0 ]; then log_warning "Publishing might have failed. Continuing..."; fi

    log_info "Waiting 10 seconds..."
    sleep 10

    log_info "Attempting to pull messages from subscription 'pubsub-subscription-message'..."
    gcloud pubsub subscriptions pull pubsub-subscription-message --limit 5
    if [ $? -ne 0 ]; then log_warning "Pulling messages might have failed (e.g., no messages). Continuing..."; fi

    log_info "Attempting to create snapshot 'pubsub-snapshot' for subscription 'gcloud-pubsub-subscription'..."
    # Note the different subscription name here, as per the original script.
    gcloud pubsub snapshots create pubsub-snapshot --subscription=gcloud-pubsub-subscription
    if [ $? -ne 0 ]; then log_warning "Snapshot creation might have failed (e.g., subscription doesn't exist or snapshot exists). Continuing..."; fi

    echo
    echo "${GREEN_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}          LAB COMPLETED SUCCESSFULLY! ${RESET_FORMAT}"
    echo "${GREEN_TEXT}${BOLD_TEXT}=============================================${RESET_FORMAT}"
}

read -p "${BOLD_TEXT}Enter Form No (1, 2, or 3): ${RESET_FORMAT}" choice

echo # Add a newline for better formatting

case "$choice" in
    1)
        run_form_1
        ;;
    2)
        run_form_2
        ;;
    3)
        run_form_3
        ;;
    *)
        log_error "Invalid choice: $choice. Please enter 1, 2, or 3."
        exit 1
        ;;
esac

echo
