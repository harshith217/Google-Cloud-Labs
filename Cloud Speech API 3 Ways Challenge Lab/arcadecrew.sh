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

# Function for displaying formatted section headers
section_header() {
    echo ""
    echo "${BLUE_TEXT}${BOLD_TEXT}=================================================${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT} $1 ${RESET_FORMAT}"
    echo "${BLUE_TEXT}${BOLD_TEXT}=================================================${RESET_FORMAT}"
    echo ""
}

# Function for displaying task completion messages
task_complete() {
    echo "${GREEN_TEXT}${BOLD_TEXT}✓ $1 completed successfully!${RESET_FORMAT}"
}

# Function for displaying error messages
error_message() {
    echo "${RED_TEXT}${BOLD_TEXT}✗ ERROR: $1${RESET_FORMAT}"
}

# Function for displaying information messages
info_message() {
    echo "${CYAN_TEXT}${BOLD_TEXT}ℹ $1${RESET_FORMAT}"
}

# Function to check if a command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        task_complete "$1"
    else
        error_message "$1 failed!"
        exit 1
    fi
}

# Welcome message and introduction
clear
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                INITIATING EXECUTION...                ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""

# User input for required variables
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter API Key: ${RESET_FORMAT}" API_KEY
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 2 file name: ${RESET_FORMAT}" task_2_file_name
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 3 request file name: ${RESET_FORMAT}" task_3_request_file
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 3 response file name: ${RESET_FORMAT}" task_3_response_file
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 4 sentence to translate: ${RESET_FORMAT}" task_4_sentence
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 4 output file name: ${RESET_FORMAT}" task_4_file
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 5 sentence for language detection: ${RESET_FORMAT}" task_5_sentence
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter Task 5 output file name: ${RESET_FORMAT}" task_5_file
echo

# Export the variables to make them available for other commands
export API_KEY
export task_2_file_name
export task_3_request_file
export task_3_response_file
export task_4_sentence
export task_4_file
export task_5_sentence
export task_5_file

# ---------------------- TASK 1: Create an API key ----------------------
section_header "TASK 1: Create an API key"
echo "${MAGENTA_TEXT}${BOLD_TEXT}You have already provided your API Key: ${API_KEY}${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}This key will be used for all API requests in this lab.${RESET_FORMAT}"
task_complete "Task 1"

# ---------------------- TASK 2: Create synthetic speech from text ----------------------
section_header "TASK 2: Create synthetic speech from text using Text-to-Speech API"

info_message "Activating virtual environment..."
source venv/bin/activate
check_success "Virtual environment activation"

info_message "Creating synthesize-text.json file..."
cat > synthesize-text.json << 'EOF'
{
    "input":{
        "text":"Cloud Text-to-Speech API allows developers to include natural-sounding, synthetic human speech as playable audio in their applications. The Text-to-Speech API converts text or Speech Synthesis Markup Language (SSML) input into audio data like MP3 or LINEAR16 (the encoding used in WAV files)."
    },
    "voice":{
        "languageCode":"en-gb",
        "name":"en-GB-Standard-A",
        "ssmlGender":"FEMALE"
    },
    "audioConfig":{
        "audioEncoding":"MP3"
    }
}
EOF
check_success "Creating synthesize-text.json file"

info_message "Calling the Text-to-Speech API to synthesize text..."
curl -s -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d @synthesize-text.json \
     "https://texttospeech.googleapis.com/v1/text:synthesize" > "${task_2_file_name}"
check_success "Text-to-Speech API call"

info_message "Creating tts_decode.py file..."
cat > tts_decode.py << 'EOF'
import argparse
from base64 import decodebytes
import json

"""
Usage:
        python tts_decode.py --input "Filled in at lab start" \
        --output "synthesize-text-audio.mp3"

"""

def decode_tts_output(input_file, output_file):
    """ Decode output from Cloud Text-to-Speech.

    input_file: the response from Cloud Text-to-Speech
    output_file: the name of the audio file to create

    """

    with open(input_file) as input:
        response = json.load(input)
        audio_data = response['audioContent']

        with open(output_file, "wb") as new_file:
            new_file.write(decodebytes(audio_data.encode('utf-8')))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Decode output from Cloud Text-to-Speech",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--input',
                       help='The response from the Text-to-Speech API.',
                       required=True)
    parser.add_argument('--output',
                       help='The name of the audio file to create',
                       required=True)

    args = parser.parse_args()
    decode_tts_output(args.input, args.output)
EOF
check_success "Creating tts_decode.py file"

info_message "Decoding the audio file..."
python tts_decode.py --input "${task_2_file_name}" --output "synthesize-text-audio.mp3"
check_success "Decoding audio file"

echo

task_complete "Task 2"

# ---------------------- TASK 3: Speech to text transcription ----------------------
section_header "TASK 3: Perform speech to text transcription with the Cloud Speech API"

info_message "Creating request file for French transcription..."
cat > "${task_3_request_file}" << EOF
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "fr-FR",
    "audioChannelCount": 2
  },
  "audio": {
    "uri": "gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
EOF
check_success "Creating request file"

info_message "Calling the Speech-to-Text API for transcription..."
curl -s -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d @"${task_3_request_file}" \
     "https://speech.googleapis.com/v1/speech:recognize" > "${task_3_response_file}"
check_success "Speech-to-Text API call"

info_message "Transcription result saved to ${task_3_response_file}"
task_complete "Task 3"

# ---------------------- TASK 4: Translate text ----------------------
section_header "TASK 4: Translate text with the Cloud Translation API"

info_message "Translating the provided sentence to English..."
encoded_text=$(echo -n "${task_4_sentence}" | jq -sRr @uri)
curl -s -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{
       'q': '${task_4_sentence}',
       'target': 'en'
     }" \
     "https://translation.googleapis.com/language/translate/v2?key=${API_KEY}" > "${task_4_file}"
check_success "Text translation"

info_message "Translation result saved to ${task_4_file}"
task_complete "Task 4"

# ---------------------- TASK 5: Detect language ----------------------
section_header "TASK 5: Detect a language with the Cloud Translation API"

info_message "Detecting language of the provided sentence..."
curl -s -X POST \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{
       'q': '${task_5_sentence}'
     }" \
     "https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" > "${task_5_file}"
check_success "Language detection"

info_message "Language detection result saved to ${task_5_file}"
task_complete "Task 5"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo ""
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
