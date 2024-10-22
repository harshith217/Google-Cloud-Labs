# Define color codes
YELLOW='\033[0;32m'
BG_RED=`tput setab 1`
TEXT_GREEN=`tput setab 2`
TEXT_RED=`tput setaf 1`

BOLD=`tput bold`
RESET=`tput sgr0`

NC='\033[0m'


echo "${BG_RED}${BOLD}Starting Execution${RESET}"

echo -e "${YELLOW}Enter the main region:${NC}"
read REGION

echo -e "${YELLOW}Enter the second region:${NC}"
read REGION2

echo -e "${YELLOW}Enter the third region:${NC}"
read REGION3

# Set the main region and corresponding default zone
gcloud config set compute/region "$REGION"
export REGION=$(gcloud config get-value compute/region)
gcloud config set compute/zone "${REGION}-c"
export ZONE=$(gcloud config get-value compute/zone)

# Create a custom VPC network with subnets in the three regions
gcloud compute networks create taw-custom-network --subnet-mode=custom

# Create subnets for the main and additional regions
gcloud compute networks subnets create subnet-$REGION --network=taw-custom-network --region=$REGION --range=10.0.0.0/16
gcloud compute networks subnets create subnet-$REGION2 --network=taw-custom-network --region=$REGION2 --range=10.1.0.0/16
gcloud compute networks subnets create subnet-$REGION3 --network=taw-custom-network --region=$REGION3 --range=10.2.0.0/16

# Add firewall rules
gcloud compute firewall-rules create nw101-allow-http --network=taw-custom-network --allow tcp:80 --target-tags=http --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create nw101-allow-icmp --network=taw-custom-network --allow icmp --target-tags=rules --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create nw101-allow-internal --network=taw-custom-network --allow tcp:0-65535,udp:0-65535,icmp --source-ranges=10.0.0.0/16,10.1.0.0/16,10.2.0.0/16
gcloud compute firewall-rules create nw101-allow-ssh --network=taw-custom-network --allow tcp:22 --target-tags=ssh --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create nw101-allow-rdp --network=taw-custom-network --allow tcp:3389 --source-ranges=0.0.0.0/0

echo -e "${TEXT_RED}${BOLD}Congratulations For Completing The Lab !!! ${RESET}"
echo -e "${TEXT_GREEN}${BOLD}Subscribe to our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET}"
