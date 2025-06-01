#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     INITIATING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}📈 Task 1. Total confirmed cases${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task calculates the total confirmed COVID-19 cases worldwide for a specific date.${RESET_FORMAT}"
echo
echo "${WHITE_TEXT}Please provide the date components when prompted. Format: MM for month, DD for day.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the month (format: MM): ${RESET_FORMAT}"
read input_month

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the date (format: DD): ${RESET_FORMAT}"
read input_day

year="2020"
input_date="${year}-${input_month}-${input_day}"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Executing BigQuery to find total cases for ${input_date}...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"SELECT sum(cumulative_confirmed) as total_cases_worldwide
 FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
 WHERE date='${input_date}'"

echo
echo "${RED_TEXT}${BOLD_TEXT}🗺️  Task 2. Worst affected areas${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task identifies US states with death counts above a specified threshold.${RESET_FORMAT}"
echo


echo -n "${GREEN_TEXT}${BOLD_TEXT}☠️  Please enter the death count threshold: ${RESET_FORMAT}"
read death_threshold

year="2020"
input_date="${year}-${input_month}-${input_day}"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Analyzing US states with deaths > ${death_threshold} on ${input_date}...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"WITH deaths_by_states AS (
    SELECT subregion1_name as state, sum(cumulative_deceased) as death_count
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='United States of America' 
      AND date='${input_date}' 
      AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
)
SELECT count(*) as count_of_states
FROM deaths_by_states
WHERE death_count > ${death_threshold}"

echo
echo "${RED_TEXT}${BOLD_TEXT}🔥 Task 3. Identify hotspots${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task finds COVID-19 hotspots by identifying states with high confirmed cases.${RESET_FORMAT}"
echo

#!/bin/bash

echo -n "${GREEN_TEXT}${BOLD_TEXT}🦠 Please enter the confirmed case threshold: ${RESET_FORMAT}"
read case_threshold

year="2020"
input_date="${year}-${input_month}-${input_day}"

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Identifying hotspots with cases > ${case_threshold} on ${input_date}...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"SELECT * FROM (
    SELECT subregion1_name as state, sum(cumulative_confirmed) as total_confirmed_cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_code='US' AND date='${input_date}' AND subregion1_name IS NOT NULL
    GROUP BY subregion1_name
    ORDER BY total_confirmed_cases DESC
)
WHERE total_confirmed_cases > ${case_threshold}"

echo
echo "${RED_TEXT}${BOLD_TEXT}💀 Task 4. Fatality ratio${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task calculates the case fatality ratio for Italy within a date range.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the start date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read start_date

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the end date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read end_date

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Calculating fatality ratio for Italy from ${start_date} to ${end_date}...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"SELECT sum(cumulative_confirmed) as total_confirmed_cases,
       sum(cumulative_deceased) as total_deaths,
       (sum(cumulative_deceased)/sum(cumulative_confirmed))*100 as case_fatality_ratio
FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
WHERE country_name='Italy' AND date BETWEEN '${start_date}' AND '${end_date}'"

echo
echo "${RED_TEXT}${BOLD_TEXT}📍 Task 5. Identifying specific day${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task finds the first day when Italy exceeded a specific death threshold.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}☠️  Please enter the death threshold: ${RESET_FORMAT}"
read death_threshold

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Finding first day Italy exceeded ${death_threshold} deaths...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"SELECT date
 FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
 WHERE country_name='Italy' AND cumulative_deceased > ${death_threshold}
 ORDER BY date ASC
 LIMIT 1"

echo
echo "${RED_TEXT}${BOLD_TEXT}📉 Task 6. Finding days with zero net new cases${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task identifies days when India had zero net new COVID-19 cases.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the start date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read start_date

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the end date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read end_date

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Analyzing India's zero net new case days from ${start_date} to ${end_date}...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"WITH india_cases_by_date AS (
    SELECT date, SUM(cumulative_confirmed) AS cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name ='India' AND date BETWEEN '${start_date}' AND '${end_date}'
    GROUP BY date
    ORDER BY date ASC
), india_previous_day_comparison AS (
    SELECT date, cases, LAG(cases) OVER(ORDER BY date) AS previous_day, cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases
    FROM india_cases_by_date
)
SELECT count(*)
FROM india_previous_day_comparison
WHERE net_new_cases = 0"

echo
echo "${RED_TEXT}${BOLD_TEXT}📈 Task 7. Doubling rate${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task analyzes the percentage increase in US COVID-19 cases during a specific period.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}📊 Please enter the percentage increase threshold: ${RESET_FORMAT}"
read percentage_threshold

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Analyzing US case growth rates above ${percentage_threshold}% (Mar 22 - Apr 20, 2020)...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"WITH us_cases_by_date AS (
    SELECT date, SUM(cumulative_confirmed) AS cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='United States of America' AND date BETWEEN '2020-03-22' AND '2020-04-20'
    GROUP BY date
    ORDER BY date ASC
), us_previous_day_comparison AS (
    SELECT date, cases, LAG(cases) OVER(ORDER BY date) AS previous_day,
           cases - LAG(cases) OVER(ORDER BY date) AS net_new_cases,
           (cases - LAG(cases) OVER(ORDER BY date))*100/LAG(cases) OVER(ORDER BY date) AS percentage_increase
    FROM us_cases_by_date
)
SELECT Date, cases AS Confirmed_Cases_On_Day, previous_day AS Confirmed_Cases_Previous_Day, percentage_increase AS Percentage_Increase_In_Cases
FROM us_previous_day_comparison
WHERE percentage_increase > ${percentage_threshold}"

echo
echo "${RED_TEXT}${BOLD_TEXT}🏥 Task 8. Recovery rate${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task calculates recovery rates for countries with significant case counts.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}🔢 Please enter the limit: ${RESET_FORMAT}"
read limit

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Calculating recovery rates for top ${limit} countries (May 10, 2020)...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"WITH cases_by_country AS (

  SELECT

    country_name AS country,

    sum(cumulative_confirmed) AS cases,

    sum(cumulative_recovered) AS recovered_cases

  FROM

    bigquery-public-data.covid19_open_data.covid19_open_data

  WHERE

    date = '2020-05-10'

  GROUP BY

    country_name

 ), recovered_rate AS

(SELECT

  country, cases, recovered_cases,

  (recovered_cases * 100)/cases AS recovery_rate

FROM cases_by_country

)
SELECT country, cases AS confirmed_cases, recovered_cases, recovery_rate

FROM recovered_rate

WHERE cases > 50000

ORDER BY recovery_rate DESC

LIMIT ${limit}"

echo
echo "${RED_TEXT}${BOLD_TEXT}📊 Task 9. CDGR - Cumulative daily growth rate${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task calculates France's cumulative daily growth rate between two dates.${RESET_FORMAT}"
echo "${WHITE_TEXT}The start date is fixed (2020-01-24). Please provide the second date for comparison.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the second date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read second_date

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Calculating France's CDGR from 2020-01-24 to ${second_date}...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"WITH france_cases AS (
    SELECT date, SUM(cumulative_confirmed) AS total_cases
    FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
    WHERE country_name='France' AND date IN ('2020-01-24', '${second_date}')
    GROUP BY date
    ORDER BY date
), summary AS (
    SELECT total_cases AS first_day_cases, LEAD(total_cases) OVER(ORDER BY date) AS last_day_cases,
           DATE_DIFF(LEAD(date) OVER(ORDER BY date), date, day) AS days_diff
    FROM france_cases
    LIMIT 1
)
SELECT first_day_cases, last_day_cases, days_diff,
       POWER((last_day_cases/first_day_cases),(1/days_diff))-1 AS cdgr
FROM summary"

echo
echo "${RED_TEXT}${BOLD_TEXT}📋 Task 10. Create a Looker Studio report${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}💡 This task prepares data for Looker Studio by extracting US COVID-19 trends.${RESET_FORMAT}"
echo

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the start date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read start_date

echo -n "${GREEN_TEXT}${BOLD_TEXT}📅 Please enter the end date (format: YYYY-MM-DD): ${RESET_FORMAT}"
read end_date

echo "${YELLOW_TEXT}${BOLD_TEXT}🔍 Generating US COVID-19 data for Looker Studio (${start_date} to ${end_date})...${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"SELECT date, SUM(cumulative_confirmed) AS country_cases,
       SUM(cumulative_deceased) AS country_deaths
FROM \`bigquery-public-data.covid19_open_data.covid19_open_data\`
WHERE date BETWEEN '${start_date}' AND '${end_date}'
  AND country_name='United States of America'
GROUP BY date
ORDER BY date"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
