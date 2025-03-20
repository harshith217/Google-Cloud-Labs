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

# Utility functions
print_section() {
    echo ""
    echo "${BLUE_TEXT}${BOLD_TEXT}=== $1 ===${RESET_FORMAT}"
    echo ""
}

print_step() {
    echo "${YELLOW_TEXT}${BOLD_TEXT}>>> $1${RESET_FORMAT}"
}

print_info() {
    echo "${CYAN_TEXT}$1${RESET_FORMAT}"
}

print_success() {
    echo "${GREEN_TEXT}${BOLD_TEXT}✓ $1${RESET_FORMAT}"
}

print_error() {
    echo "${RED_TEXT}${BOLD_TEXT}✗ ERROR: $1${RESET_FORMAT}"
}

exit_on_error() {
    if [ $? -ne 0 ]; then
        print_error "$1"
        exit 1
    fi
}

# Task 1: Get MovieLens data
task_get_movielens_data() {
    print_section "Task 1: Get MovieLens data"
    
    print_step "Creating BigQuery dataset 'movies'"
    bq --location=US mk --dataset movies
    exit_on_error "Failed to create BigQuery dataset"
    print_success "Dataset 'movies' created successfully"
    
    print_step "Loading ratings data into movies.movielens_ratings"
    bq load --source_format=CSV \
        --location=US \
        --autodetect movies.movielens_ratings \
        gs://dataeng-movielens/ratings.csv
    exit_on_error "Failed to load ratings data"
    print_success "Ratings data loaded successfully"
    
    print_step "Loading movies data into movies.movielens_movies_raw"
    bq load --source_format=CSV \
        --location=US \
        --autodetect movies.movielens_movies_raw \
        gs://dataeng-movielens/movies.csv
    exit_on_error "Failed to load movies data"
    print_success "Movies data loaded successfully"
    
    print_info "Task 1 completed: MovieLens data loaded into BigQuery"
}

# Task 2: Explore the data
task_explore_data() {
    print_section "Task 2: Explore the data"
    
    print_step "Checking dataset statistics"
    print_info "Running query to count users, movies, and total ratings..."
    bq query --use_legacy_sql=false \
    'SELECT
      COUNT(DISTINCT userId) numUsers,
      COUNT(DISTINCT movieId) numMovies,
      COUNT(*) totalRatings
    FROM
      movies.movielens_ratings'
    exit_on_error "Failed to run dataset statistics query"
    
    print_step "Examining first few movies"
    print_info "Running query to check first few movies..."
    bq query --use_legacy_sql=false \
    'SELECT
      *
    FROM
      movies.movielens_movies_raw
    WHERE
      movieId < 5'
    exit_on_error "Failed to run movie examination query"
    
    print_step "Parsing genres into an array and creating movielens_movies table"
    print_info "Running query to parse genres and create table..."
    bq query --use_legacy_sql=false \
    'CREATE OR REPLACE TABLE
      movies.movielens_movies AS
    SELECT
      * REPLACE(SPLIT(genres, "|") AS genres)
    FROM
      movies.movielens_movies_raw'
    exit_on_error "Failed to create movielens_movies table"
    print_success "Created movielens_movies table with parsed genres"
    
    print_info "Task 2 completed: Data exploration finished"
}

# Task 3: Evaluate a trained model
task_evaluate_model() {
    print_section "Task 3: Evaluate a trained model created using collaborative filtering"
    
    print_info "${MAGENTA_TEXT}${BOLD_TEXT}NOTE: The model has already been created in the cloud-training-demos project.${RESET_FORMAT}"
    print_info "${MAGENTA_TEXT}${BOLD_TEXT}This step uses a pre-trained model as creation can take up to 40 minutes.${RESET_FORMAT}"
    
    print_step "Viewing metrics for the trained model"
    print_info "Running query to evaluate the model..."
    bq query --use_legacy_sql=false \
    'SELECT * FROM ML.EVALUATE(MODEL `cloud-training-demos.movielens.recommender`)'
    exit_on_error "Failed to evaluate model"
    
    print_success "Model evaluation completed"
    print_info "Task 3 completed: Trained model evaluated"
}

# Task 4: Make recommendations
task_make_recommendations() {
    print_section "Task 4: Make recommendations"
    
    print_step "Finding best comedy movies for user 903"
    print_info "Running query to get comedy recommendations..."
    bq query --use_legacy_sql=false \
    'SELECT
      *
    FROM
      ML.PREDICT(MODEL `cloud-training-demos.movielens.recommender`,
        (
        SELECT
          movieId,
          title,
          903 AS userId
        FROM
          `movies.movielens_movies`,
          UNNEST(genres) g
        WHERE
          g = "Comedy" ))
    ORDER BY
      predicted_rating DESC
    LIMIT
      5'
    exit_on_error "Failed to get comedy recommendations"
    
    print_step "Finding comedy movies not already seen by user 903"
    print_info "Running query to get unseen comedy recommendations..."
    bq query --use_legacy_sql=false \
    'SELECT
      *
    FROM
      ML.PREDICT(MODEL `cloud-training-demos.movielens.recommender`,
        (
        WITH
          seen AS (
          SELECT
            ARRAY_AGG(movieId) AS movies
          FROM
            movies.movielens_ratings
          WHERE
            userId = 903 )
        SELECT
          movieId,
          title,
          903 AS userId
        FROM
          movies.movielens_movies,
          UNNEST(genres) g,
          seen
        WHERE
          g = "Comedy"
          AND movieId NOT IN UNNEST(seen.movies) ))
    ORDER BY
      predicted_rating DESC
    LIMIT
      5'
    exit_on_error "Failed to get unseen comedy recommendations"
    
    print_success "Recommendations generated successfully"
    print_info "Task 4 completed: Movie recommendations made"
}

# Task 5: Apply customer targeting
task_apply_customer_targeting() {
    print_section "Task 5: Apply customer targeting"
    
    print_step "Identifying users likely to rate movie 96481 highly"
    print_info "Running query to find top 100 users..."
    bq query --use_legacy_sql=false \
    'SELECT
      *
    FROM
      ML.PREDICT(MODEL `cloud-training-demos.movielens.recommender`,
        (
        WITH
          allUsers AS (
          SELECT
            DISTINCT userId
          FROM
            movies.movielens_ratings )
        SELECT
          96481 AS movieId,
          (
          SELECT
            title
          FROM
            movies.movielens_movies
          WHERE
            movieId=96481) title,
          userId
        FROM
          allUsers ))
    ORDER BY
      predicted_rating DESC
    LIMIT
      100'
    exit_on_error "Failed to identify target users"
    
    print_success "Successfully identified 100 users to target"
    print_info "Task 5 completed: Customer targeting applied"
}

# Main execution
main() {    
    # Execute tasks
    task_get_movielens_data
    task_explore_data
    task_evaluate_model
    task_make_recommendations
    task_apply_customer_targeting
}

# Run the script
main


# Completion Message
echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
