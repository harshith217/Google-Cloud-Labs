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

echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Function to display task headers
function task_header() {
    echo "${BOLD_TEXT}${YELLOW_TEXT}======== $1 ========${RESET_FORMAT}"
    echo ""
}

# Function to display step information
function step_info() {
    echo "${BOLD_TEXT}${CYAN_TEXT}>> $1${RESET_FORMAT}"
}

# Function to display success messages
function success() {
    echo "${BOLD_TEXT}${GREEN_TEXT}✓ $1${RESET_FORMAT}"
}

# Function to display error messages
function error() {
    echo "${BOLD_TEXT}${RED_TEXT}✗ $1${RESET_FORMAT}"
}

# Function to check command status
function check_status() {
    if [ $? -eq 0 ]; then
        success "$1"
    else
        error "$2"
    fi
}

# Get current project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    error "No project ID found. Please set a project ID using: gcloud config set project YOUR_PROJECT_ID"
fi

echo "${BOLD_TEXT}Running on project:${RESET_FORMAT} ${GREEN_TEXT}$PROJECT_ID${RESET_FORMAT}"
echo ""

# Task 1: Create a new dataset and machine learning model
task_header "Task 1: Create a new dataset and machine learning model"

step_info "Creating 'ecommerce' dataset..."
bq --location=US mk -d \
    --description "Dataset for ML models" \
    $PROJECT_ID:ecommerce
check_status "Dataset 'ecommerce' created successfully." "Failed to create dataset."

step_info "Creating customer_classification_model..."
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`$PROJECT_ID.ecommerce.customer_classification_model\`
OPTIONS
(
model_type='logistic_reg',
labels = ['will_buy_on_return_visit']
)
AS

#standardSQL
SELECT
* EXCEPT(fullVisitorId)
FROM

# features
(SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
FROM
    \`data-to-insights.ecommerce.web_analytics\`
WHERE
    totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430') # train on first 9 months
JOIN
(SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
FROM
    \`data-to-insights.ecommerce.web_analytics\`
GROUP BY fullvisitorid)
USING (fullVisitorId)
"
check_status "Model 'customer_classification_model' created successfully." "Failed to create model."

echo ""
success "Task 1 completed successfully!"
echo ""

# Task 2: Evaluate classification model performance
task_header "Task 2: Evaluate classification model performance"

step_info "Evaluating customer_classification_model..."
bq query --use_legacy_sql=false "
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > 0.9 THEN 'good'
    WHEN roc_auc > 0.8 THEN 'fair'
    WHEN roc_auc > 0.7 THEN 'decent'
    ELSE 'poor'
  END AS model_quality
FROM
  ML.EVALUATE(MODEL \`$PROJECT_ID.ecommerce.customer_classification_model\`,
    (
    SELECT
    * EXCEPT(fullVisitorId)
    FROM

    # features
    (SELECT
        fullVisitorId,
        IFNULL(totals.bounces, 0) AS bounces,
        IFNULL(totals.timeOnSite, 0) AS time_on_site
    FROM
        \`data-to-insights.ecommerce.web_analytics\`
    WHERE
        totals.newVisits = 1
        AND date BETWEEN '20170501' AND '20170630') # evaluate on 2 months
    JOIN
    (SELECT
        fullvisitorid,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
    FROM
        \`data-to-insights.ecommerce.web_analytics\`
    GROUP BY fullvisitorid)
    USING (fullVisitorId)
    )
)
"
check_status "Model evaluated successfully." "Failed to evaluate model."

echo ""
success "Task 2 completed successfully!"
echo ""

# Task 3: Improve model performance with Feature Engineering
task_header "Task 3: Improve model performance with Feature Engineering"

step_info "Creating improved_customer_classification_model with additional features..."
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`$PROJECT_ID.ecommerce.improved_customer_classification_model\`
OPTIONS
  (model_type='logistic_reg', labels = ['will_buy_on_return_visit']) AS

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)

# add in new features
SELECT * EXCEPT(unique_session_id) FROM (

  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory,

      # geographic
      geoNetwork.country

  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE 1=1
    # only predict for new visits
    AND totals.newVisits = 1
    AND date BETWEEN '20160801' AND '20170430' # train on first 9 months

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  geoNetwork.country
);
"
check_status "Improved model created successfully." "Failed to create improved model."

step_info "Evaluating improved_customer_classification_model..."
bq query --use_legacy_sql=false "
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > 0.9 THEN 'good'
    WHEN roc_auc > 0.8 THEN 'fair'
    WHEN roc_auc > 0.7 THEN 'decent'
    ELSE 'poor'
  END AS model_quality
FROM
  ML.EVALUATE(MODEL \`$PROJECT_ID.ecommerce.improved_customer_classification_model\`)
"
check_status "Improved model evaluated successfully." "Failed to evaluate improved model."

echo ""
success "Task 3 completed successfully!"
echo ""

# Task 4: Predict which new visitors will come back and purchase
task_header "Task 4: Predict which new visitors will come back and purchase"

step_info "Creating finalized_classification_model..."
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL \`$PROJECT_ID.ecommerce.finalized_classification_model\`
OPTIONS
  (model_type=\"logistic_reg\", labels = [\"will_buy_on_return_visit\"]) AS

WITH all_visitor_stats AS (
SELECT
  fullvisitorid,
  IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM \`data-to-insights.ecommerce.web_analytics\`
  GROUP BY fullvisitorid
)

# add in new features
SELECT * EXCEPT(unique_session_id) FROM (

  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory,

      # geographic
      IFNULL(geoNetwork.country, \"\") AS country

  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE 1=1
    # only predict for new visits
    AND totals.newVisits = 1
    AND date BETWEEN \"20160801\" AND \"20170430\" # train 9 months

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
);
"
check_status "Finalized model created successfully." "Failed to create finalized model."

step_info "Predicting which new visitors will come back and purchase..."
bq query --use_legacy_sql=false "
SELECT
  *
FROM
  ML.PREDICT(MODEL \`$PROJECT_ID.ecommerce.finalized_classification_model\`,
  (
  WITH all_visitor_stats AS (
  SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
    FROM \`data-to-insights.ecommerce.web_analytics\`
    GROUP BY fullvisitorid
  )

  # add in new features
  SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,

      # labels
      will_buy_on_return_visit,

      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,

      # behavior on the site
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,

      # where the visitor came from
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,

      # mobile or desktop
      device.deviceCategory,

      # geographic
      IFNULL(geoNetwork.country, '') AS country

  FROM \`data-to-insights.ecommerce.web_analytics\`,
    UNNEST(hits) AS h

    JOIN all_visitor_stats USING(fullvisitorid)

  WHERE 1=1
    # only predict for new visits
    AND totals.newVisits = 1
    AND date BETWEEN '20170501' AND '20170630' # last 1 month

  GROUP BY
  unique_session_id,
  will_buy_on_return_visit,
  bounces,
  time_on_site,
  totals.pageviews,
  trafficSource.source,
  trafficSource.medium,
  channelGrouping,
  device.deviceCategory,
  country
  ))
  ORDER BY predicted_will_buy_on_return_visit DESC
  LIMIT 10
"
check_status "Predictions generated successfully." "Failed to generate predictions."

echo ""
success "Task 4 completed successfully!"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
