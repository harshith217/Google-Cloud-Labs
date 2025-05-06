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

echo "${YELLOW_TEXT}${BOLD_TEXT}🔧 Setting up the environment... Fetching your GCP Project ID.${RESET_FORMAT}"
export PROJECT_ID=$(gcloud info --format='value(config.project)')
echo "${GREEN_TEXT}✅ Project ID set to: ${BOLD_TEXT}${PROJECT_ID}${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔍 Task 2: Identifying duplicate rows in the raw ecommerce dataset...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT COUNT(*) as num_duplicate_rows, * FROM
\`data-to-insights.ecommerce.all_sessions_raw\`
GROUP BY
fullVisitorId, channelGrouping, time, country, city, totalTransactionRevenue, transactions, timeOnSite, pageviews, sessionQualityDim, date, visitId, type, productRefundAmount, productQuantity, productPrice, productRevenue, productSKU, v2ProductName, v2ProductCategory, productVariant, currencyCode, itemQuantity, itemRevenue, transactionRevenue, transactionId, pageTitle, searchKeyword, pagePathLevel1, eCommerceAction_type, eCommerceAction_step, eCommerceAction_option
HAVING num_duplicate_rows > 1;
"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}📊 Task 2 Completed! ${GREEN_TEXT}${BOLD_TEXT}Duplicate records check finished.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🤔 Checking for duplicates in the processed 'all_sessions' table...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
fullVisitorId,
visitId,
date,
time,
v2ProductName,
productSKU,
type,
eCommerceAction_type,
eCommerceAction_step,
eCommerceAction_option,
  transactionRevenue,
  transactionId,
COUNT(*) as row_count
FROM
\`data-to-insights.ecommerce.all_sessions\`
GROUP BY 1,2,3 ,4, 5, 6, 7, 8, 9, 10,11,12
HAVING row_count > 1
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📈 Task 3: Starting basic SQL exploration on ecommerce data...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  COUNT(*) AS product_views,
  COUNT(DISTINCT fullVisitorId) AS unique_visitors
FROM \`data-to-insights.ecommerce.all_sessions\`;
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🚦 Analyzing visitor traffic sources...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  COUNT(DISTINCT fullVisitorId) AS unique_visitors,
  channelGrouping
FROM \`data-to-insights.ecommerce.all_sessions\`
GROUP BY channelGrouping
ORDER BY channelGrouping DESC;
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛍️ Listing all unique product names...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  (v2ProductName) AS ProductName
FROM \`data-to-insights.ecommerce.all_sessions\`
GROUP BY ProductName
ORDER BY ProductName
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🔝 Identifying the Top 5 most viewed products...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  COUNT(*) AS product_views,
  (v2ProductName) AS ProductName
FROM \`data-to-insights.ecommerce.all_sessions\`
WHERE type = 'PAGE'
GROUP BY v2ProductName
ORDER BY product_views DESC
LIMIT 5;
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}👀 Finding the Top 5 products viewed by the most unique visitors...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
WITH unique_product_views_by_person AS (
SELECT
 fullVisitorId,
 (v2ProductName) AS ProductName
FROM \`data-to-insights.ecommerce.all_sessions\`
WHERE type = 'PAGE'
GROUP BY fullVisitorId, v2ProductName )
SELECT
  COUNT(*) AS unique_view_count,
  ProductName
FROM unique_product_views_by_person
GROUP BY ProductName
ORDER BY unique_view_count DESC
LIMIT 5
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🛒 Correlating product views with orders for the Top 5 viewed products...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  COUNT(*) AS product_views,
  COUNT(productQuantity) AS orders,
  SUM(productQuantity) AS quantity_product_ordered,
  v2ProductName
FROM \`data-to-insights.ecommerce.all_sessions\`
WHERE type = 'PAGE'
GROUP BY v2ProductName
ORDER BY product_views DESC
LIMIT 5;
"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}📊 Calculating average quantity per order for the Top 5 viewed products...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"
SELECT
  COUNT(*) AS product_views,
  COUNT(productQuantity) AS orders,
  SUM(productQuantity) AS quantity_product_ordered,
  SUM(productQuantity) / COUNT(productQuantity) AS avg_per_order,
  (v2ProductName) AS ProductName
FROM \`data-to-insights.ecommerce.all_sessions\`
WHERE type = 'PAGE'
GROUP BY v2ProductName
ORDER BY product_views DESC
LIMIT 5;
"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🎉 Task 3 Completed! ${GREEN_TEXT}${BOLD_TEXT}Basic SQL exploration finished.${RESET_FORMAT}"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo

