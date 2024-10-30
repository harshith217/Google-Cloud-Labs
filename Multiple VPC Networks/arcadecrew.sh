# Define color codes for output formatting
YELLOW_COLOR='\033[0;33m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`

BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`

NO_COLOR='\033[0m'

echo "${BACKGROUND_RED}${BOLD_TEXT}Initiating Execution...${RESET_FORMAT}"

# Fetch zones for instances
export INSTANCE_ZONE_1=$(gcloud compute instances list mynet-vm-1 --format 'csv[no-heading](zone)')
export INSTANCE_ZONE_2=$(gcloud compute instances list mynet-vm-2 --format 'csv[no-heading](zone)')

# Determine regions from zones
export REGION_1=$(echo "$INSTANCE_ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$INSTANCE_ZONE_2" | cut -d '-' -f 1-2)

# Set up the management network
gcloud compute networks create managementnet --subnet-mode=custom

# Add the management subnet in the first region
gcloud compute networks subnets create managementsubnet-1 --network=managementnet --region=$REGION_1 --range=10.130.0.0/20

# Configure the private network
gcloud compute networks create privatenet --subnet-mode=custom

# Establish first private subnet in the initial region
gcloud compute networks subnets create privatesubnet-1 --network=privatenet --region=$REGION_1 --range=172.16.0.0/24

# Set up the second private subnet in the alternate region
gcloud compute networks subnets create privatesubnet-2 --network=privatenet --region=$REGION_2 --range=172.20.0.0/20

# Define firewall rules before launching instances
gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=managementnet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp --direction=INGRESS --priority=1000 --network=privatenet --action=ALLOW --rules=icmp,tcp:22,tcp:3389 --source-ranges=0.0.0.0/0

# Launch Instances
gcloud compute instances create managementnet-vm-1 --zone=$INSTANCE_ZONE_1 --machine-type=e2-micro --subnet=managementsubnet-1
gcloud compute instances create privatenet-vm-1 --zone=$INSTANCE_ZONE_1 --machine-type=e2-micro --subnet=privatesubnet-1

# Deploy the appliance instance with network interfaces
gcloud compute instances create vm-appliance \
--zone=$INSTANCE_ZONE_1 \
--machine-type=e2-standard-4 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=privatesubnet-1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=managementsubnet-1 \
--network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=mynetwork

# Completion message
echo -e "${RED_TEXT}${BOLD_TEXT}Lab Completed Successfully!${RESET_FORMAT}"
echo -e "${GREEN_TEXT}${BOLD_TEXT}Check out our Channel: \e]8;;https://www.youtube.com/@Arcade61432\e\\https://www.youtube.com/@Arcade61432\e]8;;\e\\${RESET_FORMAT}"
