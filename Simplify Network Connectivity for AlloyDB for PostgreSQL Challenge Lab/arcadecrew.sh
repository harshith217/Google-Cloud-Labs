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

read -p "${YELLOW_TEXT}${BOLD_TEXT}ENTER CLUSTER_ID: ${RESET_FORMAT}" CLUSTER_ID
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}ENTER PASSWORD: ${RESET_FORMAT}" PASSWORD
echo
read -p "${YELLOW_TEXT}${BOLD_TEXT}ENTER INSTANCE_ID: ${RESET_FORMAT}" INSTANCE_ID
echo

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

PROJECT_ID=`gcloud config get-value project`

echo "${MAGENTA_TEXT}${BOLD_TEXT}Using Project: $PROJECT_ID ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Using Region: $REGION ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}Using Zone: $ZONE ${RESET_FORMAT}"

# Set compute region
gcloud config set compute/region $REGION

echo "${BLUE_TEXT}${BOLD_TEXT}Starting Task 1: Setting up VPC peering for AlloyDB...${RESET_FORMAT}"
# Create address for VPC peering
gcloud compute addresses create psa-range \
    --global \
    --purpose=VPC_PEERING \
    --addresses=10.8.12.0 \
    --prefix-length=24 \
    --network=cloud-vpc

# Connect VPC peering
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --network=cloud-vpc \
    --ranges=psa-range

# Update peering settings
gcloud compute networks peerings update servicenetworking-googleapis-com \
    --network=cloud-vpc \
    --export-custom-routes \
    --import-custom-routes

echo "${GREEN_TEXT}${BOLD_TEXT}Task 1 completed: VPC peering set up successfully.${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Starting Task 2: Creating AlloyDB cluster and instance...${RESET_FORMAT}"
# Task 2: Create AlloyDB cluster
gcloud alloydb clusters create $CLUSTER_ID \
    --region=$REGION \
    --network=cloud-vpc \
    --password=$PASSWORD \
    --allocated-ip-range-name=psa-range

# Create AlloyDB instance
gcloud alloydb instances create $INSTANCE_ID \
    --region=$REGION \
    --cluster=$CLUSTER_ID \
    --instance-type=PRIMARY \
    --cpu-count=2

echo "${GREEN_TEXT}${BOLD_TEXT}Task 2 completed: AlloyDB cluster and instance created successfully.${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Starting Task 4: Setting up VPN connectivity...${RESET_FORMAT}"
# Task 4: Set up VPN gateways and tunnels
gcloud beta compute vpn-gateways create cloud-vpc-vpn-gw1 --network cloud-vpc --region "$REGION"

gcloud beta compute vpn-gateways create on-prem-vpn-gw1 --network on-prem-vpc --region "$REGION"

gcloud beta compute vpn-gateways describe cloud-vpc-vpn-gw1 --region "$REGION"

gcloud beta compute vpn-gateways describe on-prem-vpn-gw1 --region "$REGION"

gcloud compute routers create cloud-vpc-router1 \
    --region "$REGION" \
    --network cloud-vpc \
    --asn 65001

gcloud compute routers create on-prem-vpc-router1 \
    --region "$REGION" \
    --network on-prem-vpc \
    --asn 65002

# Generate a shared secret for VPN tunnels
SHARED_SECRET=$(openssl rand -base64 24)
echo "${GREEN_TEXT}${BOLD_TEXT}Generated shared secret for VPN tunnels.${RESET_FORMAT}"

# Create VPN tunnels
gcloud beta compute vpn-tunnels create cloud-vpc-tunnel0 \
    --peer-gcp-gateway on-prem-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret "$SHARED_SECRET" \
    --router cloud-vpc-router1 \
    --vpn-gateway cloud-vpc-vpn-gw1 \
    --interface 0

gcloud beta compute vpn-tunnels create cloud-vpc-tunnel1 \
    --peer-gcp-gateway on-prem-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret "$SHARED_SECRET" \
    --router cloud-vpc-router1 \
    --vpn-gateway cloud-vpc-vpn-gw1 \
    --interface 1

gcloud beta compute vpn-tunnels create on-prem-vpc-tunnel0 \
    --peer-gcp-gateway cloud-vpc-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret "$SHARED_SECRET" \
    --router on-prem-vpc-router1 \
    --vpn-gateway on-prem-vpn-gw1 \
    --interface 0

gcloud beta compute vpn-tunnels create on-prem-vpc-tunnel1 \
    --peer-gcp-gateway cloud-vpc-vpn-gw1 \
    --region "$REGION" \
    --ike-version 2 \
    --shared-secret "$SHARED_SECRET" \
    --router on-prem-vpc-router1 \
    --vpn-gateway on-prem-vpn-gw1 \
    --interface 1

# Configure BGP sessions
gcloud compute routers add-interface cloud-vpc-router1 \
    --interface-name if-tunnel0-to-on-prem-vpc \
    --ip-address 169.254.0.1 \
    --mask-length 30 \
    --vpn-tunnel cloud-vpc-tunnel0 \
    --region "$REGION"

gcloud compute routers add-bgp-peer cloud-vpc-router1 \
    --peer-name bgp-on-prem-tunnel0 \
    --interface if-tunnel0-to-on-prem-vpc \
    --peer-ip-address 169.254.0.2 \
    --peer-asn 65002 \
    --region "$REGION"

gcloud compute routers add-interface cloud-vpc-router1 \
    --interface-name if-tunnel1-to-on-prem-vpc \
    --ip-address 169.254.1.1 \
    --mask-length 30 \
    --vpn-tunnel cloud-vpc-tunnel1 \
    --region "$REGION"

gcloud compute routers add-bgp-peer cloud-vpc-router1 \
    --peer-name bgp-on-prem-vpc-tunnel1 \
    --interface if-tunnel1-to-on-prem-vpc \
    --peer-ip-address 169.254.1.2 \
    --peer-asn 65002 \
    --region "$REGION"

gcloud compute routers add-interface on-prem-vpc-router1 \
    --interface-name if-tunnel0-to-cloud-vpc \
    --ip-address 169.254.0.2 \
    --mask-length 30 \
    --vpn-tunnel on-prem-vpc-tunnel0 \
    --region "$REGION"

gcloud compute routers add-bgp-peer on-prem-vpc-router1 \
    --peer-name bgp-cloud-vpc-tunnel0 \
    --interface if-tunnel0-to-cloud-vpc \
    --peer-ip-address 169.254.0.1 \
    --peer-asn 65001 \
    --region "$REGION"

gcloud compute routers add-interface on-prem-vpc-router1 \
    --interface-name if-tunnel1-to-cloud-vpc \
    --ip-address 169.254.1.2 \
    --mask-length 30 \
    --vpn-tunnel on-prem-vpc-tunnel1 \
    --region "$REGION"

gcloud compute routers add-bgp-peer on-prem-vpc-router1 \
    --peer-name bgp-cloud-vpc-tunnel1 \
    --interface if-tunnel1-to-cloud-vpc \
    --peer-ip-address 169.254.1.1 \
    --peer-asn 65001 \
    --region "$REGION"

# Configure firewall rules
gcloud compute firewall-rules create vpc-demo-allow-subnets-from-on-prem \
    --network cloud-vpc \
    --allow tcp,udp,icmp \
    --source-ranges 192.168.1.0/24

gcloud compute firewall-rules create on-prem-allow-subnets-from-vpc-demo \
    --network on-prem-vpc \
    --allow tcp,udp,icmp \
    --source-ranges 10.1.1.0/24,10.2.1.0/24

# Update BGP routing mode
gcloud compute networks update cloud-vpc --bgp-routing-mode GLOBAL

echo "${GREEN_TEXT}${BOLD_TEXT}Task 4 completed: VPN connectivity set up successfully.${RESET_FORMAT}"

echo "${BLUE_TEXT}${BOLD_TEXT}Starting Task 5: Setting up custom routes...${RESET_FORMAT}"
# Task 5: Configure custom routes
gcloud compute routes create alloydb-custom-route \
    --network=on-prem-vpc \
    --destination-range=10.8.12.0/24 \
    --next-hop-vpn-tunnel=on-prem-vpc-tunnel0 \
    --priority=1000

gcloud compute routes create alloydb-return-route \
    --network=cloud-vpc \
    --destination-range=10.1.1.0/24 \
    --next-hop-vpn-tunnel=cloud-vpc-tunnel0 \
    --priority=1000

echo "${GREEN_TEXT}${BOLD_TEXT}Task 5 completed: Custom routes set up successfully.${RESET_FORMAT}"

# Get the IP address of AlloyDB instance
echo "${BLUE_TEXT}${BOLD_TEXT}Getting AlloyDB instance details...${RESET_FORMAT}"
ALLOYDB_DETAILS=$(gcloud alloydb instances describe $INSTANCE_ID --region=$REGION --cluster=$CLUSTER_ID)
ALLOYDB_IP=$(echo "$ALLOYDB_DETAILS" | grep "ipAddress:" | awk '{print $2}')

echo "${YELLOW_TEXT}${BOLD_TEXT}AlloyDB IP address: $ALLOYDB_IP"

# Create SQL file with queries
echo "${BLUE_TEXT}${BOLD_TEXT}Creating SQL file with database queries...${RESET_FORMAT}"
cat > /tmp/db_queries.sql << 'EOL'
CREATE TABLE IF NOT EXISTS patients (
    patient_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    medical_record_number VARCHAR(100) UNIQUE,
    last_visit_date DATE,
    primary_physician VARCHAR(100)
);

INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, medical_record_number, last_visit_date, primary_physician)
VALUES 
(1, 'John', 'Doe', '1985-07-12', 'MRN123456', '2024-02-20', 'Dr. Smith'),
(2, 'Jane', 'Smith', '1990-11-05', 'MRN654321', '2024-02-25', 'Dr. Johnson')
ON CONFLICT (patient_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS clinical_trials (
    trial_id INT PRIMARY KEY,
    trial_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    lead_researcher VARCHAR(100),
    number_of_participants INT,
    trial_status VARCHAR(20)
);

INSERT INTO clinical_trials (trial_id, trial_name, start_date, end_date, lead_researcher, number_of_participants, trial_status)
VALUES 
    (1, 'Trial A', '2025-01-01', '2025-12-31', 'Dr. John Doe', 200, 'Ongoing'),
    (2, 'Trial B', '2025-02-01', '2025-11-30', 'Dr. Jane Smith', 150, 'Completed')
ON CONFLICT (trial_id) DO NOTHING;

SELECT 'Database setup completed successfully.' AS status;
EOL

# Create script to run on VM
cat > /tmp/run_queries.sh << EOF
#!/bin/bash
echo "${BLUE_TEXT}${BOLD_TEXT}Connecting to AlloyDB at $ALLOYDB_IP...${RESET_FORMAT}"
export PGPASSWORD="$PASSWORD"
psql -h $ALLOYDB_IP -U postgres -d postgres -f /tmp/db_queries.sql
exit_code=\$?
if [ \$exit_code -eq 0 ]; then
    echo "${GREEN_TEXT}${BOLD_TEXT}Database operations completed successfully!${RESET_FORMAT}"
else
    echo "${RED_TEXT}${BOLD_TEXT}Database operations failed with exit code \$exit_code"
fi
EOF

echo "${BLUE_TEXT}${BOLD_TEXT}Copying files to cloud-vm...${RESET_FORMAT}"
gcloud compute scp /tmp/db_queries.sql cloud-vm:/tmp/db_queries.sql --zone=$ZONE
gcloud compute scp /tmp/run_queries.sh cloud-vm:/tmp/run_queries.sh --zone=$ZONE

echo "${BLUE_TEXT}${BOLD_TEXT}Making script executable on cloud-vm...${RESET_FORMAT}"
gcloud compute ssh cloud-vm --zone=$ZONE --command="chmod +x /tmp/run_queries.sh"

echo "${BLUE_TEXT}${BOLD_TEXT}Connecting to cloud-vm and executing PostgreSQL queries...${RESET_FORMAT}"
gcloud compute ssh cloud-vm --zone=$ZONE --command="/tmp/run_queries.sh"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}              Lab Completed Successfully!               ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Subscribe our Channel:${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
