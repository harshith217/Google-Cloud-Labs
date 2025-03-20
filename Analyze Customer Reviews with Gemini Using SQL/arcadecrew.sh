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

clear

# Welcome message
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         INITIATING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Step 1: Create a Cloud Resource Connection
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a Cloud Resource Connection${RESET_FORMAT}"
bq mk --connection --location=US --project_id=$DEVSHELL_PROJECT_ID --connection_type=CLOUD_RESOURCE gemini_conn

# Step 2: Exporting service account
echo "${GREEN_TEXT}${BOLD_TEXT}Exporting service account${RESET_FORMAT}"
export SERVICE_ACCOUNT=$(bq show --format=json --connection $DEVSHELL_PROJECT_ID.US.gemini_conn | jq -r '.cloudResource.serviceAccountId')

# Step 3: Adding IAM Policy Binding for AI Platform User
echo "${YELLOW_TEXT}${BOLD_TEXT}Adding IAM Policy Binding for AI Platform User${RESET_FORMAT}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member=serviceAccount:$SERVICE_ACCOUNT \
    --role="roles/aiplatform.user"

# Step 4: Adding IAM Policy Binding for Storage Object Admin
echo "${BLUE_TEXT}${BOLD_TEXT}Adding IAM Policy Binding for Storage Object Admin${RESET_FORMAT}"
gcloud storage buckets add-iam-policy-binding gs://$DEVSHELL_PROJECT_ID-bucket \
    --member="serviceAccount:$SERVICE_ACCOUNT" \
    --role="roles/storage.objectAdmin"

# Step 5: Creating BigQuery Dataset gemini_demo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating BigQuery Dataset gemini_demo${RESET_FORMAT}"
bq --location=US mk gemini_demo

# Step 6: Loading customer reviews data from CSV
echo "${CYAN_TEXT}${BOLD_TEXT}Loading customer reviews data from CSV${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
LOAD DATA OVERWRITE gemini_demo.customer_reviews
(customer_review_id INT64, customer_id INT64, location_id INT64, review_datetime DATETIME, review_text STRING, social_media_source STRING, social_media_handle STRING)
FROM FILES (
  format = 'CSV',
  uris = ['gs://$DEVSHELL_PROJECT_ID-bucket/gsp1246/customer_reviews.csv']);
"

sleep 15

# Step 7: Creating or replacing external table for review images
echo "${GREEN_TEXT}${BOLD_TEXT}Creating or replacing external table for review images${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE EXTERNAL TABLE
  \`gemini_demo.review_images\`
WITH CONNECTION \`us.gemini_conn\`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://$DEVSHELL_PROJECT_ID-bucket/gsp1246/images/*']
  );
"

sleep 30

# Step 8: Creating or replacing gemini_pro model
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating or replacing gemini_pro model${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`gemini_demo.gemini_pro\`
REMOTE WITH CONNECTION \`us.gemini_conn\`
OPTIONS (endpoint = 'gemini-pro')
"

sleep 30

# Step 9: Creating or replacing gemini_pro_vision model
echo "${BLUE_TEXT}${BOLD_TEXT}Creating or replacing gemini_pro_vision model${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`gemini_demo.gemini_pro_vision\`
REMOTE WITH CONNECTION \`us.gemini_conn\`
OPTIONS (endpoint = 'gemini-pro-vision')
"

sleep 30

# Step 10: Generating text for review images
echo "${RED_TEXT}${BOLD_TEXT}Generating text for review images${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.review_images_results\` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL \`gemini_demo.gemini_pro_vision\`,
    TABLE \`gemini_demo.review_images\`,
    STRUCT( 0.2 AS temperature,
        'For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list.' AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));
"

sleep 30

# Step 11: Generating text for review images
echo "${RED_TEXT}${BOLD_TEXT}Generating text for review images${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.review_images_results\` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL \`gemini_demo.gemini_pro_vision\`,
    TABLE \`gemini_demo.review_images\`,
    STRUCT( 0.2 AS temperature,
        'For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list.' AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));
"

# Step 12: Viewing the generated results
echo "${MAGENTA_TEXT}${BOLD_TEXT}Viewing the generated results${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results\`
"

# Step 13: Formatting the review images results
echo "${CYAN_TEXT}${BOLD_TEXT}Formatting the review images results${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
  `gemini_demo.review_images_results_formatted` AS (
  SELECT
    uri,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.summary") AS summary,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.keywords") AS keywords
  FROM
    `gemini_demo.review_images_results` results )
'

# Step 14: Viewing the formatted review images results
echo "${GREEN_TEXT}${BOLD_TEXT}Viewing the formatted review images results${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results_formatted\`
"

# Step 15: Generating customer reviews keywords
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating customer reviews keywords${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.customer_reviews_keywords\` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL \`gemini_demo.gemini_pro\`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'For each review, provide keywords from the review. Answer in JSON format with one key: keywords. Keywords should be a list.',
      review_text) AS prompt
   FROM \`gemini_demo.customer_reviews\`
),
STRUCT(
   0.2 AS temperature, TRUE AS flatten_json_output)));
"

# Step 16: Viewing customer reviews keywords
echo "${BLUE_TEXT}${BOLD_TEXT}Viewing customer reviews keywords${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_keywords\`
"

# Step 17: Generating sentiment analysis for customer reviews
echo "${RED_TEXT}${BOLD_TEXT}Generating sentiment analysis for customer reviews${RESET_FORMAT}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`gemini_demo.customer_reviews_analysis\` AS (
  SELECT 
    ml_generate_text_llm_result, 
    social_media_source, 
    review_text, 
    customer_id, 
    location_id, 
    review_datetime
  FROM
    ML.GENERATE_TEXT(
      MODEL \`gemini_demo.gemini_pro\`,
      (
        SELECT 
          social_media_source, 
          customer_id, 
          location_id, 
          review_text, 
          review_datetime, 
          CONCAT(
            'Classify the sentiment of the following text as positive or negative.',
            review_text, 
            'In your response don\'t include the sentiment explanation. Remove all extraneous information from your response, it should be a boolean response either positive or negative.'
          ) AS prompt
        FROM \`gemini_demo.customer_reviews\`
      ),
      STRUCT(
        0.2 AS temperature, 
        TRUE AS flatten_json_output
      )
    )
);
"

# Step 18: Viewing customer reviews sentiment analysis
echo "${MAGENTA_TEXT}${BOLD_TEXT}Viewing customer reviews sentiment analysis${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_analysis\`
ORDER BY review_datetime
"

# Step 19: Creating cleaned data view for customer reviews
echo "${CYAN_TEXT}${BOLD_TEXT}Creating cleaned data view for customer reviews${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE VIEW gemini_demo.cleaned_data_view AS
SELECT REPLACE(REPLACE(LOWER(ml_generate_text_llm_result), '.', ''), ' ', '') AS sentiment, 
REGEXP_REPLACE(
      REGEXP_REPLACE(
            REGEXP_REPLACE(social_media_source, r'Google(\+|\sReviews|\sLocal|\sMy\sBusiness|\sreviews|\sMaps)?', 'Google'), 
            'YELP', 'Yelp'
      ),
      r'SocialMedia1?', 'Social Media'
   ) AS social_media_source,
review_text, customer_id, location_id, review_datetime
FROM \`gemini_demo.customer_reviews_analysis\`;
"

# Step 20: Viewing cleaned data view
echo "${GREEN_TEXT}${BOLD_TEXT}Viewing cleaned data view${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.cleaned_data_view\`
ORDER BY review_datetime
"

# Step 21: Counting sentiment occurrences
echo "${YELLOW_TEXT}${BOLD_TEXT}Counting sentiment occurrences${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT sentiment, COUNT(*) AS count
FROM \`gemini_demo.cleaned_data_view\`
WHERE sentiment IN ('positive', 'negative')
GROUP BY sentiment; 
"

# Step 22: Counting sentiment by social media source
echo "${RED_TEXT}${BOLD_TEXT}Counting sentiment by social media source${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT sentiment, social_media_source, COUNT(*) AS count
FROM \`gemini_demo.cleaned_data_view\`
WHERE sentiment IN ('positive') OR sentiment IN ('negative')
GROUP BY sentiment, social_media_source
ORDER BY sentiment, count;    
"

# Step 23: Generating marketing incentives for reviews
echo "${GREEN_TEXT}${BOLD_TEXT}Generating marketing incentives for reviews${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.customer_reviews_marketing\` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL \`gemini_demo.gemini_pro\`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'You are a marketing representative. How could we incentivise this customer with this positive review? Provide a single response, and should be simple and concise, do not include emojis. Answer in JSON format with one key: marketing. Marketing should be a string.', review_text) AS prompt
   FROM \`gemini_demo.customer_reviews\`
   WHERE customer_id = 5576
),
STRUCT(
   0.2 AS temperature, TRUE AS flatten_json_output)));
"

# Step 24: Viewing the customer reviews marketing table
echo "${YELLOW_TEXT}${BOLD_TEXT}Viewing the customer reviews marketing table${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_marketing\`
"

# Step 25: Formatting the marketing responses
echo "${BLUE_TEXT}${BOLD_TEXT}Formatting the marketing responses${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_marketing_formatted` AS (
SELECT
   review_text,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.marketing") AS marketing,
   social_media_source, customer_id, location_id, review_datetime
FROM
   `gemini_demo.customer_reviews_marketing` results )
'

# Step 26: Viewing the formatted marketing responses
echo "${MAGENTA_TEXT}${BOLD_TEXT}Viewing the formatted marketing responses${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_marketing_formatted\`
"

# Step 27: Generating customer service responses for reviews
echo "${CYAN_TEXT}${BOLD_TEXT}Generating customer service responses for reviews${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
\`gemini_demo.customer_reviews_cs_response\` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL \`gemini_demo.gemini_pro\`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'How would you respond to this customer review? If the customer says the coffee is weak or burnt, respond stating "thank you for the review we will provide your response to the location that you did not like the coffee and it could be improved." Or if the review states the service is bad, respond to the customer stating, "the location they visited has been notfied and we are taking action to improve our service at that location." From the customer reviews provide actions that the location can take to improve. The response and the actions should be simple, and to the point. Do not include any extraneous or special characters in your response. Answer in JSON format with two keys: Response, and Actions. Response should be a string. Actions should be a string.', review_text) AS prompt
   FROM \`gemini_demo.customer_reviews\`
   WHERE customer_id = 8844
),
STRUCT(
   0.2 AS temperature, TRUE AS flatten_json_output)));
"

# Step 28: Viewing customer service responses
echo "${GREEN_TEXT}${BOLD_TEXT}Viewing customer service responses${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_cs_response\`
"

# Step 29: Formatting the customer service responses
echo "${YELLOW_TEXT}${BOLD_TEXT}Formatting the customer service responses${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_cs_response_formatted` AS (
SELECT
   review_text,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.Response") AS Response,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.Actions") AS Actions,
   social_media_source, customer_id, location_id, review_datetime
FROM
   `gemini_demo.customer_reviews_cs_response` results )
'

# Step 30: Viewing the formatted customer service responses
echo "${BLUE_TEXT}${BOLD_TEXT}Viewing the formatted customer service responses${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.customer_reviews_cs_response_formatted\`
"

# Step 31: Generating results from review images with model gemini_pro_vision
echo "${RED_TEXT}${BOLD_TEXT}Generating results from review images with model gemini_pro_vision${RESET_FORMAT}"
bq query --use_legacy_sql=false '
CREATE OR REPLACE TABLE
`gemini_demo.review_images_results` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL `gemini_demo.gemini_pro_vision`,
    TABLE `gemini_demo.review_images`,
    STRUCT( 0.2 AS temperature,
        "For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list." AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));'

# Step 32: Viewing the final review images results
echo "${GREEN_TEXT}${BOLD_TEXT}Viewing the final review images results${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results\`
"

# Step 33: Formatting the review images results
echo "${YELLOW_TEXT}${BOLD_TEXT}Formatting the review images results${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'
CREATE OR REPLACE TABLE
  `gemini_demo.review_images_results_formatted` AS (
  SELECT
    uri,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.summary") AS summary,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.keywords") AS keywords
  FROM
    `gemini_demo.review_images_results` results )
'

# Step 34: Viewing the formatted review images results
echo "${CYAN_TEXT}${BOLD_TEXT}Viewing the formatted review images results${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT * FROM \`gemini_demo.review_images_results_formatted\`
"

echo

# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
