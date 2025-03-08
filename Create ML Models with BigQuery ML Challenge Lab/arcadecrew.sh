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
UNDERLINE_TEXT=$'\033[4m'

# Displaying start message
echo
echo "${CYAN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                  Starting the process...                   ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}Creating a new BigQuery dataset named 'austin'...${RESET_FORMAT}"
bq mk austin

echo "${GREEN_TEXT}${BOLD_TEXT}Creating a new BigQuery dataset named 'bq_dataset' in the US location...${RESET_FORMAT}"
bq --location=US mk --dataset bq_dataset

export EVALUATION_YEAR=2019
echo "${YELLOW_TEXT}${BOLD_TEXT}EVALUATION_YEAR set to 2019${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating or replacing the 'austin_location_model' model...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL austin.austin_location_model
OPTIONS (
  model_type='linear_reg',
  labels=['duration_minutes']
) AS
SELECT
  start_station_name,
  EXTRACT(HOUR FROM start_time) AS start_hour,
  EXTRACT(DAYOFWEEK FROM start_time) AS day_of_week,
  duration_minutes,
  address AS location
FROM
  \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
JOIN
  \`bigquery-public-data.austin_bikeshare.bikeshare_stations\` AS stations
ON
  trips.start_station_name = stations.name
WHERE
  EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR
  AND duration_minutes > 0;
"

echo "${CYAN_TEXT}${BOLD_TEXT}Evaluating the 'austin_location_model' model...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT
  SQRT(mean_squared_error) AS rmse,
  mean_absolute_error
FROM
  ML.EVALUATE(MODEL austin.austin_location_model, (
  SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    EXTRACT(DAYOFWEEK FROM start_time) AS day_of_week,
    duration_minutes,
    address AS location
  FROM
    \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
  JOIN
    \`bigquery-public-data.austin_bikeshare.bikeshare_stations\` AS stations
  ON
    trips.start_station_name = stations.name
  WHERE EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR)
)"

echo "${CYAN_TEXT}${BOLD_TEXT}Evaluating the 'location_model'...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT
  SQRT(mean_squared_error) AS rmse,
  mean_absolute_error
FROM
  ML.EVALUATE(MODEL austin.location_model, (
  SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    EXTRACT(DAYOFWEEK FROM start_time) AS day_of_week,
    duration_minutes,
    address as location
  FROM
    \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
  JOIN
   \`bigquery-public-data.austin_bikeshare.bikeshare_stations\` AS stations
  ON
    trips.start_station_name = stations.name
  WHERE EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR)
)"

echo "${CYAN_TEXT}${BOLD_TEXT}Evaluating the 'subscriber_model'...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT
  SQRT(mean_squared_error) AS rmse,
  mean_absolute_error
FROM
  ML.EVALUATE(MODEL austin.subscriber_model, (
  SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    subscriber_type,
    duration_minutes
  FROM
    \`bigquery-public-data.austin_bikeshare.bikeshare_trips\` AS trips
  WHERE
    EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR)
)"

echo "${CYAN_TEXT}${BOLD_TEXT}Finding the number of trips per start station...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT
  start_station_name,
  COUNT(*) AS trips
FROM
  \`bigquery-public-data.austin_bikeshare.bikeshare_trips\`
WHERE
  EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR
GROUP BY
  start_station_name
ORDER BY
  trips DESC
"

echo "${CYAN_TEXT}${BOLD_TEXT}Predicting average trip length for 'Single Trip' subscribers starting at '21st & Speedway @PCL'...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT AVG(predicted_duration_minutes) AS average_predicted_trip_length
FROM ML.predict(MODEL austin.subscriber_model, (
SELECT
    start_station_name,
    EXTRACT(HOUR FROM start_time) AS start_hour,
    subscriber_type,
    duration_minutes
FROM
  \`bigquery-public-data.austin_bikeshare.bikeshare_trips\`
WHERE
  EXTRACT(YEAR FROM start_time) = $EVALUATION_YEAR
  AND subscriber_type = 'Single Trip'
  AND start_station_name = '21st & Speedway @PCL'))"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating or replacing the 'customer_classification_model' model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL \`ecommerce.customer_classification_model\`
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
;
"

echo "${CYAN_TEXT}${BOLD_TEXT}Creating or replacing the 'customer_classification_model' model with logistic regression...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
CREATE OR REPLACE MODEL \`ecommerce.customer_classification_model\`
OPTIONS(model_type='logistic_reg') AS
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20160801' AND '20170631'
LIMIT 100000;
"

echo "${CYAN_TEXT}${BOLD_TEXT}Evaluating the 'customer_classification_model' model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  *
FROM
  ml.EVALUATE(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'));
"

echo "${CYAN_TEXT}${BOLD_TEXT}Predicting total purchases by country...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  country,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY country
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

echo "${CYAN_TEXT}${BOLD_TEXT}Predicting total purchases by visitor...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  fullVisitorId,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`ecommerce.customer_classification_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country,
  fullVisitorId
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY fullVisitorId
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

echo "${GREEN_TEXT}${BOLD_TEXT}Creating a new BigQuery dataset named 'bq_dataset' in the US location...${RESET_FORMAT}"
bq --location=US mk --dataset bq_dataset

echo "${CYAN_TEXT}${BOLD_TEXT}Creating or replacing the 'predicts_visitor_model' model...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL bqml_dataset.predicts_visitor_model
OPTIONS(model_type='logistic_reg') AS
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20160801' AND '20170631'
  LIMIT 100000;
"

echo "${CYAN_TEXT}${BOLD_TEXT}Evaluating the 'predicts_visitor_model' model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  *
FROM
  ml.EVALUATE(MODEL \`bqml_dataset.predicts_visitor_model\`, (
SELECT
  IF(totals.transactions IS NULL, 0, 1) AS label,
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(geoNetwork.country, '') AS country,
  IFNULL(totals.pageviews, 0) AS pageviews
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'));
"

echo "${CYAN_TEXT}${BOLD_TEXT}Predicting total purchases by country...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  country,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`bqml_dataset.predicts_visitor_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY country
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

echo "${CYAN_TEXT}${BOLD_TEXT}Predicting total purchases by visitor...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  fullVisitorId,
  SUM(predicted_label) as total_predicted_purchases
FROM
  ml.PREDICT(MODEL \`bqml_dataset.predicts_visitor_model\`, (
SELECT
  IFNULL(device.operatingSystem, '') AS os,
  device.isMobile AS is_mobile,
  IFNULL(totals.pageviews, 0) AS pageviews,
  IFNULL(geoNetwork.country, '') AS country,
  fullVisitorId
FROM
  \`bigquery-public-data.google_analytics_sample.ga_sessions_*\`
WHERE
  _TABLE_SUFFIX BETWEEN '20170701' AND '20170801'))
GROUP BY fullVisitorId
ORDER BY total_predicted_purchases DESC
LIMIT 10;
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
