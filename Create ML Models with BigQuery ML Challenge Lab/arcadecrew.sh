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
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📊 Creating a new BigQuery dataset named 'ecommerce' in the US location...${RESET_FORMAT}"
bq --location=US mk -d ecommerce

echo "${MAGENTA_TEXT}${BOLD_TEXT}🧠 Training the first logistic regression model (customer_classification_model)...${RESET_FORMAT}"
bq query --use_legacy_sql=false '
CREATE OR REPLACE MODEL `ecommerce.customer_classification_model`
OPTIONS
(
  model_type="logistic_reg",
  labels = ["will_buy_on_return_visit"]
) AS

SELECT
  * EXCEPT(fullVisitorId)
FROM
  (SELECT
    fullVisitorId,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    totals.newVisits = 1
    AND date BETWEEN "20160801" AND "20170430") # train on first 9 months
JOIN
  (SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM
    `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid)
USING (fullVisitorId)'

echo "${YELLOW_TEXT}${BOLD_TEXT}📈 Evaluating the performance of the initial model...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > 0.9 THEN 'good'
    WHEN roc_auc > 0.8 THEN 'fair'
    WHEN roc_auc > 0.7 THEN 'decent'
    WHEN roc_auc > 0.6 THEN 'not great'
    ELSE 'poor'
  END AS model_quality
FROM
  ML.EVALUATE(MODEL ecommerce.customer_classification_model, (
    SELECT
      * EXCEPT(fullVisitorId)
    FROM (
      SELECT
        fullVisitorId,
        IFNULL(totals.bounces, 0) AS bounces,
        IFNULL(totals.timeOnSite, 0) AS time_on_site
      FROM \`data-to-insights.ecommerce.web_analytics\`
      WHERE totals.newVisits = 1
        AND date BETWEEN '20170501' AND '20170630'
    )
    JOIN (
      SELECT
        fullVisitorId,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM \`data-to-insights.ecommerce.web_analytics\`
      GROUP BY fullVisitorId
    )
    USING (fullVisitorId)
  ));
"

echo "${CYAN_TEXT}${BOLD_TEXT}✨ Training an improved model (improved_customer_classification_model) with more features...${RESET_FORMAT}"
bq query --use_legacy_sql=false '
CREATE OR REPLACE MODEL `ecommerce.improved_customer_classification_model`
OPTIONS (
  model_type="logistic_reg",
  input_label_cols = ["will_buy_on_return_visit"]
) AS

WITH all_visitor_stats AS (
  SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
    CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
    will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    IFNULL(totals.pageviews, 0) AS pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    IFNULL(geoNetwork.country, "") AS country
  FROM `data-to-insights.ecommerce.web_analytics`,
    UNNEST(hits) AS h
  JOIN all_visitor_stats USING(fullvisitorid)
  WHERE totals.newVisits = 1
    AND date BETWEEN "20160801" AND "20170430"
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
)'

echo "${RED_TEXT}${BOLD_TEXT}📊 Evaluating the performance of the improved model...${RESET_FORMAT}"
bq query --use_legacy_sql=false "
SELECT
  roc_auc,
  CASE
    WHEN roc_auc > 0.9 THEN 'good'
    WHEN roc_auc > 0.8 THEN 'fair'
    WHEN roc_auc > 0.7 THEN 'decent'
    WHEN roc_auc > 0.6 THEN 'not great'
    ELSE 'poor'
  END AS model_quality
FROM
  ML.EVALUATE(MODEL \`ecommerce.improved_customer_classification_model\`, (
    WITH all_visitor_stats AS (
      SELECT
        fullvisitorid,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM \`data-to-insights.ecommerce.web_analytics\`
      GROUP BY fullvisitorid
    )
    SELECT
      CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      IFNULL(totals.pageviews, 0) AS pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, '') AS country
    FROM \`data-to-insights.ecommerce.web_analytics\`,
      UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
    WHERE totals.newVisits = 1
      AND date BETWEEN '20170501' AND '20170630'
    GROUP BY
      unique_session_id,
      will_buy_on_return_visit,
      bounces,
      time_on_site,
      pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      country
  ));
"

echo "${GREEN_TEXT}${BOLD_TEXT}🏆 Training the finalized model (finalized_classification_model) using selected features...${RESET_FORMAT}"
bq query --use_legacy_sql=false '
CREATE OR REPLACE MODEL `ecommerce.finalized_classification_model`
OPTIONS (
  model_type="logistic_reg",
  labels = ["will_buy_on_return_visit"]
) AS

WITH all_visitor_stats AS (
  SELECT
    fullvisitorid,
    IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullvisitorid
)

SELECT * EXCEPT(unique_session_id) FROM (
  SELECT
    CONCAT(fullvisitorid, CAST(visitId AS STRING)) AS unique_session_id,
    will_buy_on_return_visit,
    MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
    IFNULL(totals.bounces, 0) AS bounces,
    IFNULL(totals.timeOnSite, 0) AS time_on_site,
    IFNULL(totals.pageviews, 0) AS pageviews,
    trafficSource.source,
    trafficSource.medium,
    channelGrouping,
    device.deviceCategory,
    IFNULL(geoNetwork.country, "") AS country
  FROM `data-to-insights.ecommerce.web_analytics`,
    UNNEST(hits) AS h
  JOIN all_visitor_stats USING(fullvisitorid)
  WHERE totals.newVisits = 1
    AND date BETWEEN "20160801" AND "20170430"
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
)'

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔮 Making predictions using the finalized model on new data...${RESET_FORMAT}"
bq query --use_legacy_sql=false '
SELECT
  *
FROM
  ML.PREDICT(MODEL `ecommerce.finalized_classification_model`, (
    WITH all_visitor_stats AS (
      SELECT
        fullvisitorid,
        IF(COUNTIF(totals.transactions > 0 AND totals.newVisits IS NULL) > 0, 1, 0) AS will_buy_on_return_visit
      FROM `data-to-insights.ecommerce.web_analytics`
      GROUP BY fullvisitorid
    )
    SELECT
      CONCAT(fullvisitorid, "-", CAST(visitId AS STRING)) AS unique_session_id,
      will_buy_on_return_visit,
      MAX(CAST(h.eCommerceAction.action_type AS INT64)) AS latest_ecommerce_progress,
      IFNULL(totals.bounces, 0) AS bounces,
      IFNULL(totals.timeOnSite, 0) AS time_on_site,
      totals.pageviews,
      trafficSource.source,
      trafficSource.medium,
      channelGrouping,
      device.deviceCategory,
      IFNULL(geoNetwork.country, "") AS country
    FROM `data-to-insights.ecommerce.web_analytics`,
      UNNEST(hits) AS h
    JOIN all_visitor_stats USING(fullvisitorid)
    WHERE totals.newVisits = 1
      AND date BETWEEN "20170701" AND "20170801"
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
ORDER BY
  predicted_will_buy_on_return_visit DESC'


echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
