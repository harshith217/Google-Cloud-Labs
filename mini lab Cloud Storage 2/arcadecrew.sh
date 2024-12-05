#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Randomly select colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

echo ""
echo ""

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"
echo ""

curl -LO 

echo "${BOLD}${CYAN}Step 1: Fetching the current Google Cloud project ID...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

echo "${BOLD}${CYAN}Step 2: Applying the lifecycle configuration to the GCS bucket...${RESET}"
gsutil lifecycle set lifecycle.json gs://$PROJECT_ID-bucket

echo

function random_congrats() {
    MESSAGES=(
        "${GREEN}Kudos! You've successfully wrapped up the lab! Keep reaching new heights!${RESET}"
        "${CYAN}Fantastic work! Your efforts are truly commendable!${RESET}"
        "${YELLOW}Outstanding achievement! You’ve accomplished something wonderful!${RESET}"
        "${BLUE}Bravo! Your dedication and focus have made this a success!${RESET}"
        "${MAGENTA}Hats off! You’re progressing brilliantly!${RESET}"
        "${RED}Terrific job! This milestone is all thanks to your perseverance!${RESET}"
        "${CYAN}Way to go! You’re proving your skills with every step!${RESET}"
        "${GREEN}Amazing effort! Completing this lab is a testament to your drive!${RESET}"
        "${YELLOW}Incredible! Your hard work is a shining example!${RESET}"
        "${BLUE}You did it! Celebrate this well-deserved success!${RESET}"
        "${MAGENTA}Well done! This is a leap forward in your journey!${RESET}"
        "${RED}Superb! Your commitment and skill are truly shining!${RESET}"
        "${CYAN}Great work! Keep breaking barriers and achieving new goals!${RESET}"
        "${GREEN}Cheers to your success! This is a step closer to mastery!${RESET}"
        "${YELLOW}Splendid! Your effort is paving the way to greatness!${RESET}"
        "${BLUE}Inspiring work! Keep this positive momentum going!${RESET}"
        "${MAGENTA}Amazing accomplishment! Your passion is paying off!${RESET}"
        "${RED}You’ve done it again! Keep striving for excellence!${RESET}"
        "${CYAN}Impressive results! Your persistence is admirable!${RESET}"
        "${GREEN}Fantastic! Each step you take adds to your success story!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

random_congrats

echo -e "\n"  

cd

remove_files() {
    
    for file in *; do
        
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            
            if [[ -f "$file" ]]; then
                
                rm "$file"
                echo "Removed file: $file"
            fi
        fi
    done
}

remove_files


echo ""
# Completion message
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"

