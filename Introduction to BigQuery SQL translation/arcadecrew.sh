#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'
BLUE_TEXT=$'\033[0;34m'

# Start of the script
echo
echo "${CYAN_TEXT}${BOLD_TEXT}Starting the process...${RESET_FORMAT}"
echo

GCP_PROJECT_ID=$(gcloud config get-value project)
echo "${GREEN_TEXT}${BOLD_TEXT}Using GCP Project ID: ${YELLOW_TEXT}$GCP_PROJECT_ID${RESET_FORMAT}"

# Enable the BigQuery Migration API
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Enabling the BigQuery Migration API...${RESET_FORMAT}"
gcloud services enable bigquerymigration.googleapis.com

# Create the source_teradata.txt file
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Creating the source_teradata.txt file...${RESET_FORMAT}"
cat <<EOF > source_teradata.txt
-- Create a new table named "Customers"
CREATE TABLE Customers (
  CustomerID INTEGER PRIMARY KEY,
  FirstName VARCHAR(255),
  LastName VARCHAR(255),
  Email VARCHAR(255)
);

-- Insert some data into the "Customers" table
INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
VALUES (1, 'John', 'Doe', 'johndoe@example.com');

INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
VALUES (2, 'Jane', 'Smith', 'janesmith@example.com');

INSERT INTO Customers (CustomerID, FirstName, LastName, Email)
VALUES (3, 'Bob', 'Johnson', 'bobjohnson@example.com');

-- Select all data from the "Customers" table
SELECT * FROM Customers;

-- Add a new column to the "Customers" table
ALTER TABLE Customers ADD Address VARCHAR(255);

-- Update the email address for a specific customer
UPDATE Customers SET Email = 'johndoe2@example.com' WHERE CustomerID = 1;

-- Delete a customer record from the "Customers" table
DELETE FROM Customers WHERE CustomerID = 3;

-- Select customers whose first name starts with 'J'
SELECT * FROM Customers WHERE FirstName LIKE 'J%';
EOF

# Create the Google Cloud Storage bucket
echo
echo "${BLUE_TEXT}${BOLD_TEXT}Creating a Google Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://$GCP_PROJECT_ID

# Copy the source_teradata.txt file to the bucket
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying the source_teradata.txt file to the bucket...${RESET_FORMAT}"
gsutil cp source_teradata.txt gs://$GCP_PROJECT_ID/source/source_teradata.txt
echo


# Safely delete the script if it exists
SCRIPT_NAME="arcadecrew.sh"
if [ -f "$SCRIPT_NAME" ]; then
    echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
    rm -- "$SCRIPT_NAME"
fi

echo
echo
# Completion message
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}NOW FOLLOW STEPS IN THE VIDEO.${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
