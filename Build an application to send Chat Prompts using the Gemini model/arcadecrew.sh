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

echo "${YELLOW_TEXT}${BOLD_TEXT}Enter REGION:${RESET_FORMAT}"
read -r REGION
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Region set to:${RESET_FORMAT} ${CYAN_TEXT}$REGION${RESET_FORMAT}"

export REGION
ID="$(gcloud projects list --format='value(PROJECT_ID)')"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}Project ID:${RESET_FORMAT} ${CYAN_TEXT}$ID${RESET_FORMAT}"
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating SendChatwithoutStream.py...${RESET_FORMAT}"


cat > SendChatwithoutStream.py <<EOF
import vertexai
from vertexai.generative_models import GenerativeModel, ChatSession

import logging
from google.cloud import logging as gcp_logging

# ------  Below cloud logging code is for Qwiklab's internal use, do not edit/remove it. --------
# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

project_id = "$ID"
location = "$REGION"

vertexai.init(project=project_id, location=location)
model = GenerativeModel("gemini-1.0-pro")
chat = model.start_chat()

def get_chat_response(chat: ChatSession, prompt: str) -> str:
    logging.info(f'Sending prompt: {prompt}')
    response = chat.send_message(prompt)
    logging.info(f'Received response: {response.text}')
    return response.text

prompt = "Hello."
print(get_chat_response(chat, prompt))

prompt = "What are all the colors in a rainbow?"
print(get_chat_response(chat, prompt))

prompt = "Why does it appear when it rains?"
print(get_chat_response(chat, prompt))

EOF
echo "${GREEN_TEXT}${BOLD_TEXT}Executing SendChatwithoutStream.py...${RESET_FORMAT}"
/usr/bin/python3 /home/student/SendChatwithoutStream.py
echo
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating SendChatwithStream.py...${RESET_FORMAT}"

cat > SendChatwithStream.py <<EOF
import vertexai
from vertexai.generative_models import GenerativeModel, ChatSession

import logging
from google.cloud import logging as gcp_logging

# ------  Below cloud logging code is for Qwiklab's internal use, do not edit/remove it. --------
# Initialize GCP logging
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

project_id = "$ID"
location = "$REGION"

vertexai.init(project=project_id, location=location)
model = GenerativeModel("gemini-1.0-pro")
chat = model.start_chat()

def get_chat_response(chat: ChatSession, prompt: str) -> str:
    text_response = []
    logging.info(f'Sending prompt: {prompt}')
    responses = chat.send_message(prompt, stream=True)
    for chunk in responses:
        text_response.append(chunk.text)
    return "".join(text_response)
    logging.info(f'Received response: {response.text}')

prompt = "Hello."
print(get_chat_response(chat, prompt))

prompt = "What are all the colors in a rainbow?"
print(get_chat_response(chat, prompt))

prompt = "Why does it appear when it rains?"
print(get_chat_response(chat, prompt))

EOF

echo "${GREEN_TEXT}${BOLD_TEXT}Executing SendChatwithStream.py...${RESET_FORMAT}"
/usr/bin/python3 /home/student/SendChatwithStream.py
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
