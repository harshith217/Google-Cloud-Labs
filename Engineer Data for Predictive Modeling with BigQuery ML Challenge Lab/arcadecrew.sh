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

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter TABLE_NAME: ${RESET_FORMAT}" TABLE_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter FARE_AMOUNT_NAME: ${RESET_FORMAT}" FARE_AMOUNT_NAME
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter TRIP_DISTANCE_NO: ${RESET_FORMAT}" TRIP_DISTANCE_NO
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter FARE_AMOUNT: ${RESET_FORMAT}" FARE_AMOUNT
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter PASSENGER_COUNT: ${RESET_FORMAT}" PASSENGER_COUNT
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter MODEL_NAME: ${RESET_FORMAT}" MODEL_NAME

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📊 Configuration Summary 📊${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}TABLE_NAME: ${RESET_FORMAT}${CYAN_TEXT}$TABLE_NAME${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}FARE_AMOUNT_NAME: ${RESET_FORMAT}${CYAN_TEXT}$FARE_AMOUNT_NAME${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}TRIP_DISTANCE_NO: ${RESET_FORMAT}${CYAN_TEXT}$TRIP_DISTANCE_NO${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}FARE_AMOUNT: ${RESET_FORMAT}${CYAN_TEXT}$FARE_AMOUNT${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}PASSENGER_COUNT: ${RESET_FORMAT}${CYAN_TEXT}$PASSENGER_COUNT${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}MODEL_NAME: ${RESET_FORMAT}${CYAN_TEXT}$MODEL_NAME${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🧹 Task 1: Data Cleaning & Preparation${RESET_FORMAT}"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE
  taxirides.$TABLE_NAME AS
SELECT
  (tolls_amount + fare_amount) AS $FARE_AMOUNT_NAME,
  pickup_datetime,
  pickup_longitude AS pickuplon,
  pickup_latitude AS pickuplat,
  dropoff_longitude AS dropofflon,
  dropoff_latitude AS dropofflat,
  passenger_count AS passengers,
FROM
  taxirides.historical_taxi_rides_raw
WHERE
  RAND() < 0.001
  AND trip_distance > $TRIP_DISTANCE_NO
  AND fare_amount >= $FARE_AMOUNT
  AND pickup_longitude > -78
  AND pickup_longitude < -70
  AND dropoff_longitude > -78
  AND dropoff_longitude < -70
  AND pickup_latitude > 37
  AND pickup_latitude < 45
  AND dropoff_latitude > 37
  AND dropoff_latitude < 45
  AND passenger_count > $PASSENGER_COUNT
"

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 1 completed successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}❌ Task 1 failed${RESET_FORMAT}"
    exit 1
fi

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🤖 Task 2: ML Model Creation & Training${RESET_FORMAT}"

bq query --use_legacy_sql=false "
CREATE OR REPLACE MODEL taxirides.$MODEL_NAME
TRANSFORM(
  * EXCEPT(pickup_datetime)

  , ST_Distance(ST_GeogPoint(pickuplon, pickuplat), ST_GeogPoint(dropofflon, dropofflat)) AS euclidean
  , CAST(EXTRACT(DAYOFWEEK FROM pickup_datetime) AS STRING) AS dayofweek
  , CAST(EXTRACT(HOUR FROM pickup_datetime) AS STRING) AS hourofday
)
OPTIONS(input_label_cols=['$FARE_AMOUNT_NAME'], model_type='linear_reg')
AS

SELECT * FROM taxirides.$TABLE_NAME
"

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 2 completed successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}❌ Task 2 failed${RESET_FORMAT}"
    exit 1
fi

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}🔮 Task 3: Batch Prediction Generation${RESET_FORMAT}"

bq query --use_legacy_sql=false "
CREATE OR REPLACE TABLE taxirides.2015_fare_amount_predictions
  AS
SELECT * FROM ML.PREDICT(MODEL taxirides.$MODEL_NAME,(
  SELECT * FROM taxirides.report_prediction_data)
)
"

if [ $? -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}✅ Task 3 completed successfully${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}❌ Task 3 failed${RESET_FORMAT}"
    exit 1
fi

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 IF YOU FOUND THIS HELPFUL, SUBSCRIBE ARCADE CREW! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
