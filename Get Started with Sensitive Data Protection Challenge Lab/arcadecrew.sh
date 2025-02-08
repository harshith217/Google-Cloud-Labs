#!/bin/bash

# Define color variables
YELLOW_TEXT=$'\033[0;33m'
MAGENTA_TEXT=$'\033[0;35m'
NO_COLOR=$'\033[0m'
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=$'\033[0;31m'
CYAN_TEXT=$'\033[0;36m'
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=$'\033[0;34m'

echo
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

echo

# Display instruction for creating redact-request.json
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Creating redact-request.json file...${RESET_FORMAT}"
cat > redact-request.json <<EOF_END
{
	"item": {
		"value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
	},
	"deidentifyConfig": {
		"infoTypeTransformations": {
			"transformations": [{
				"primitiveTransformation": {
					"replaceWithInfoTypeConfig": {}
				}
			}]
		}
	},
	"inspectConfig": {
		"infoTypes": [{
				"name": "EMAIL_ADDRESS"
			},
			{
				"name": "US_HEALTHCARE_NPI"
			}
		]
	}
}
EOF_END

# Display instruction for sending redact request
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Sending redact request to DLP API...${RESET_FORMAT}"
curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/content:deidentify \
  -d @redact-request.json -o redact-response.txt

# Display instruction for uploading response to Google Cloud Storage
echo -e "${GREEN_TEXT}${BOLD_TEXT}Uploading redact-response.txt to Google Cloud Storage...${RESET_FORMAT}"
gsutil cp redact-response.txt gs://$DEVSHELL_PROJECT_ID-redact

# Display instruction for creating template.json
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Creating structured_data_template.json file...${RESET_FORMAT}"
cat > template.json <<EOF_END
{
	"deidentifyTemplate": {
	  "deidentifyConfig": {
		"recordTransformations": {
		  "fieldTransformations": [
			{
			  "fields": [
				{
				  "name": "bank name"
				},
				{
				  "name": "zip code"
				}
				
			  ],
			  "primitiveTransformation": {
				"characterMaskConfig": {
				  "maskingCharacter": "#"
				  
				}
				
			  }
			  
			}
			
		  ]
		  
		}
		
	  },
	  "displayName": "structured_data_template"
	  
	},
	"locationId": "global",
	"templateId": "structured_data_template"
  }
EOF_END

# Display instruction for sending structured_data_template to DLP API
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Sending structured_data_template to DLP API...${RESET_FORMAT}"
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/deidentifyTemplates \
-d @template.json

# Display instruction for creating unstructured_data_template.json
echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Creating unstructured_data_template.json file...${RESET_FORMAT}"
cat > template.json <<'EOF_END'
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "infoTypes": [
              {
                "name": ""
                
              }
              
            ],
            "primitiveTransformation": {
              "replaceConfig": {
                "newValue": {
                  "stringValue": "[redacted]"
                  
                }
              }
              
            }
          }
          
        ]
      }
      
    },
    "displayName": "unstructured_data_template"
    
  },
  "templateId": "unstructured_data_template",
  "locationId": "global"
}
EOF_END

# Display instruction for sending unstructured_data_template to DLP API
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Sending unstructured_data_template to DLP API...${RESET_FORMAT}"
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/deidentifyTemplates \
-d @template.json

# Output the URLs for the templates
echo -e "${GREEN_TEXT}${BOLD_TEXT}Structured Data Template URL:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/structured_data_template/edit?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

echo -e "${GREEN_TEXT}${BOLD_TEXT}Unstructured Data Template URL:${RESET_FORMAT}"
echo -e "${BLUE_TEXT}https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/unstructured_data_template/edit?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"

# Display the message with colors
echo -e "${CYAN_TEXT}${BOLD_TEXT}Now please follow the instructions provided in the video.${RESET}"

# # Safely delete the script if it exists
# SCRIPT_NAME="arcadecrew.sh"
# if [ -f "$SCRIPT_NAME" ]; then
#     echo -e "${BOLD_TEXT}${RED_TEXT}Deleting the script ($SCRIPT_NAME) for safety purposes...${RESET_FORMAT}${NO_COLOR}"
#     rm -- "$SCRIPT_NAME"
# fi

# echo
# echo
# # Completion message
# echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
# echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo