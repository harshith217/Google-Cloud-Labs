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

echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter 1st ZONE:${RESET_FORMAT}"
read -r ZONE_1
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter 2nd ZONE:${RESET_FORMAT}"
read -r ZONE_2
echo -e "${YELLOW_TEXT}${BOLD_TEXT}Enter 3rd ZONE:${RESET_FORMAT}"
read -r ZONE_3

echo -e "${GREEN_TEXT}${BOLD_TEXT}You entered:${RESET_FORMAT}"
echo -e "${GREEN_TEXT}Zone 1: ${BOLD_TEXT}$ZONE_1${RESET_FORMAT}"
echo -e "${GREEN_TEXT}Zone 2: ${BOLD_TEXT}$ZONE_2${RESET_FORMAT}"
echo -e "${GREEN_TEXT}Zone 3: ${BOLD_TEXT}$ZONE_3${RESET_FORMAT}"

export REGION_1="${ZONE_1%-*}"
export REGION_2="${ZONE_2%-*}"
export REGION_3="${ZONE_3%-*}"

echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Creating instances...${RESET_FORMAT}"

gcloud compute instances create us-test-01 \
--subnet subnet-$REGION_1 \
--zone $ZONE_1 \
--machine-type e2-standard-2 \
--tags ssh,http,rules

gcloud compute instances create us-test-02 \
--subnet subnet-$REGION_2 \
--zone $ZONE_2 \
--machine-type e2-standard-2 \
--tags ssh,http,rules


gcloud compute instances create us-test-03 \
--subnet subnet-$REGION_3 \
--zone $ZONE_3 \
--machine-type e2-standard-2 \
--tags ssh,http,rules


gcloud compute instances create us-test-04 \
--subnet subnet-$REGION_1 \
--zone $ZONE_1 \
--tags ssh,http

echo -e "${MAGENTA_TEXT}${BOLD_TEXT}Preparing instances with necessary tools...${RESET_FORMAT}"

cat > prepare_disk1.sh <<'EOF_END'
sudo apt-get update
sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege
traceroute www.icann.org

EOF_END

gcloud compute scp prepare_disk1.sh us-test-01:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet

gcloud compute ssh us-test-01 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk1.sh"


cat > prepare_disk2.sh <<'EOF_END'
sudo apt-get update

sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege
EOF_END

gcloud compute scp prepare_disk2.sh us-test-02:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet

gcloud compute ssh us-test-02 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_2 --quiet --command="bash /tmp/prepare_disk2.sh"

cat > prepare_disk.sh3 <<'EOF_END'
sudo apt-get update

sudo apt-get -y install traceroute mtr tcpdump iperf whois host dnsutils siege

EOF_END

gcloud compute scp prepare_disk.sh3 us-test-04:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet

gcloud compute ssh us-test-04 --project=$DEVSHELL_PROJECT_ID --zone=$ZONE_1 --quiet --command="bash /tmp/prepare_disk.sh3"

cat > prepare_disk.sh4 <<'EOF_END'

EOF_END

AVAILABLE_ZONES=$(gcloud compute zones list --filter="region:($REGION)" --format="value(name)" | grep -v "$ZONE_1" | head -n 1)

if [ -z "$AVAILABLE_ZONES" ]; then
    echo "No alternative zones found in $REGION"
    exit 1
fi

ZONE=$AVAILABLE_ZONES

gcloud compute scp prepare_disk.sh4 mc-server:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh mc-server --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh4"
echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
