#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`

# Display initiation message
echo "${BACKGROUND_RED}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`

# Display initiation message
echo "${BACKGROUND_RED}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

# Prompt the user for inputs in yellow bold color
echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the API Key: ${NO_COLOR}${RESET_FORMAT}"
read API_KEY

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 2 file name: ${NO_COLOR}${RESET_FORMAT}"
read task_2_file_name

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 3 request file name: ${NO_COLOR}${RESET_FORMAT}"
read task_3_request_file

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 3 response file name: ${NO_COLOR}${RESET_FORMAT}"
read task_3_response_file

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 4 sentence: ${NO_COLOR}${RESET_FORMAT}"
read task_4_sentence

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 4 file name: ${NO_COLOR}${RESET_FORMAT}"
read task_4_file

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 5 sentence: ${NO_COLOR}${RESET_FORMAT}"
read task_5_sentence

echo -e "${YELLOW_COLOR}${BOLD_TEXT}Enter the task 5 file name: ${NO_COLOR}${RESET_FORMAT}"
read task_5_file

audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"

export PROJECT_ID=$(gcloud config get-value project)

source venv/bin/activate

cat > synthesize-text.json <<EOF
{
  "input": {
    "text": "Cloud Text-to-Speech API allows developers to include natural-sounding, synthetic human speech as playable audio in their applications. The Text-to-Speech API converts text or Speech Synthesis Markup Language (SSML) input into audio data like MP3 or LINEAR16 (the encoding used in WAV files)."
  },
  "voice": {
    "languageCode": "en-gb",
    "name": "en-GB-Standard-A",
    "ssmlGender": "FEMALE"
  },
  "audioConfig": {
    "audioEncoding": "MP3"
  }
}
EOF

curl -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
> $task_2_file_name

cat > "$task_3_request_file" <<EOF
{
  "config": {
    "encoding": "FLAC",
    "sampleRateHertz": 44100,
    "languageCode": "fr-FR"
  },
  "audio": {
    "uri": "$audio_uri"
  }
}
EOF

curl -s -X POST -H "Content-Type: application/json" \
--data-binary @"$task_3_request_file" \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
-o "$task_3_response_file"

response=$(curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": \"$task_4_sentence\"}" \
"https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en")
echo "$response" > "$task_4_file"

curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": [\"$task_5_sentence\"]}" \
"https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
-o "$task_5_file"

# Completion message
echo -e "${RED_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Check out our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET_FORMAT}"
