#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}📍 Step 1: Determining the default Google Cloud region...${RESET_FORMAT}"
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
echo "${GREEN_TEXT}✅ Default region set to: ${REGION}${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}🔒 Step 2: Activating the Identity-Aware Proxy (IAP) API...${RESET_FORMAT}"
gcloud services enable iap.googleapis.com
echo "${GREEN_TEXT}✅ IAP service enabled successfully.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}🛠️ Step 3: Setting up a new Compute Engine instance template...${RESET_FORMAT}"
gcloud compute instance-templates create instance-template-1 --project=$DEVSHELL_PROJECT_ID --machine-type=e2-micro --network-interface=network=default,network-tier=PREMIUM --metadata=^,@^startup-script=\#\ Copyright\ 2021\ Google\ LLC$'\n'\#$'\n'\#\ Licensed\ under\ the\ Apache\ License,\ Version\ 2.0\ \(the\ \"License\"\)\;$'\n'\#\ you\ may\ not\ use\ this\ file\ except\ in\ compliance\ with\ the\ License.\#\ You\ may\ obtain\ a\ copy\ of\ the\ License\ at$'\n'\#$'\n'\#\ http://www.apache.org/licenses/LICENSE-2.0$'\n'\#$'\n'\#\ Unless\ required\ by\ applicable\ law\ or\ agreed\ to\ in\ writing,\ software$'\n'\#\ distributed\ under\ the\ License\ is\ distributed\ on\ an\ \"AS\ IS\"\ BASIS,$'\n'\#\ WITHOUT\ WARRANTIES\ OR\ CONDITIONS\ OF\ ANY\ KIND,\ either\ express\ or\ implied.$'\n'\#\ See\ the\ License\ for\ the\ specific\ language\ governing\ permissions\ and$'\n'\#\ limitations\ under\ the\ License.$'\n'apt-get\ -y\ update$'\n'apt-get\ -y\ install\ git$'\n'apt-get\ -y\ install\ virtualenv$'\n'git\ clone\ https://github.com/GoogleCloudPlatform/python-docs-samples$'\n'cd\ python-docs-samples/iap$'\n'virtualenv\ venv\ -p\ python3$'\n'source\ venv/bin/activate$'\n'pip\ install\ -r\ requirements.txt$'\n'cat\ example_gce_backend.py\ \|$'\n'sed\ -e\ \"s/YOUR_BACKEND_SERVICE_ID/\$\(gcloud\ compute\ backend-services\ describe\ my-backend-service\ --global--format=\"value\(id\)\"\)/g\"\ \|$'\n'\ \ \ \ sed\ -e\ \"s/YOUR_PROJECT_ID/\$\(gcloud\ config\ get-value\ account\ \|\ tr\ -cd\ \"\[0-9\]\"\)/g\"\ \>\ real_backend.py$'\n'gunicorn\ real_backend:app\ -b\ 0.0.0.0:80,@enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-template-1,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230509,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/compute.readonly
echo "${GREEN_TEXT}✅ Instance template 'instance-template-1' created.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🩺 Step 4: Establishing a health check for the instance group...${RESET_FORMAT}"
gcloud beta compute health-checks create http my-health-check \
  --project=$DEVSHELL_PROJECT_ID \
  --port=80 \
  --request-path=/ \
  --check-interval=5 \
  --timeout=5 \
  --unhealthy-threshold=2 \
  --healthy-threshold=2
echo "${GREEN_TEXT}✅ Health check 'my-health-check' configured.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🏗️ Step 5: Constructing a managed instance group...${RESET_FORMAT}"
gcloud beta compute instance-groups managed create my-managed-instance-group \
  --project=$DEVSHELL_PROJECT_ID \
  --base-instance-name=my-managed-instance-group \
  --size=1 \
  --template=instance-template-1 \
  --region=$REGION \
  --health-check=my-health-check \
  --initial-delay=300
echo "${GREEN_TEXT}✅ Managed instance group 'my-managed-instance-group' created in region ${REGION}.${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔑 Step 6: Generating a self-signed SSL certificate...${RESET_FORMAT}"
openssl genrsa -out PRIVATE_KEY_FILE 2048

cat > ssl_config <<EOF
[req]
default_bits = 2048
req_extensions = extension_requirements
distinguished_name = dn_requirements
prompt = no

[extension_requirements]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[dn_requirements]
countryName = US
stateOrProvinceName = CA
localityName = Mountain View
0.organizationName = Cloud
organizationalUnitName = Example
commonName = Test
EOF

openssl req -new -key PRIVATE_KEY_FILE \
 -out CSR_FILE \
 -config ssl_config

openssl x509 -req \
 -signkey PRIVATE_KEY_FILE \
 -in CSR_FILE \
 -out CERTIFICATE_FILE.pem \
 -extfile ssl_config \
 -extensions extension_requirements \
 -days 365
echo "${GREEN_TEXT}✅ SSL certificate files generated (PRIVATE_KEY_FILE, CSR_FILE, CERTIFICATE_FILE.pem).${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}☁️ Step 7: Uploading the SSL certificate to Google Cloud...${RESET_FORMAT}"
gcloud compute ssl-certificates create my-cert \
 --certificate=CERTIFICATE_FILE.pem \
 --private-key=PRIVATE_KEY_FILE \
 --global
echo "${GREEN_TEXT}✅ SSL certificate 'my-cert' created in GCP.${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}🛡️ Step 8: Configuring the backend service and applying security policies...${RESET_FORMAT}"
echo "${YELLOW_TEXT}   Creating default security policy...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "description": "Default security policy for: my-backend-service",
       "name": "default-security-policy-for-backend-service-my-backend-service",
       "rules": [
         {
           "action": "allow",
           "match": {
             "config": {
               "srcIpRanges": [
                 "*"
               ]
             },
             "versionedExpr": "SRC_IPS_V1"
           },
           "priority": 2147483647
         },
         {
           "action": "throttle",
           "description": "Default rate limiting rule",
           "match": {
             "config": {
               "srcIpRanges": [
                 "*"
               ]
             },
             "versionedExpr": "SRC_IPS_V1"
           },
           "priority": 2147483646,
           "rateLimitOptions": {
             "conformAction": "allow",
             "enforceOnKey": "IP",
             "exceedAction": "deny(403)",
             "rateLimitThreshold": {
               "count": 500,
               "intervalSec": 60
             }
           }
         }
       ]
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies"

echo "${YELLOW_TEXT}   Waiting 30 seconds...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  printf "\r${YELLOW_TEXT}   %2d seconds remaining...${RESET_FORMAT}" "$i"
  sleep 1
done
printf "\r${YELLOW_TEXT}   Waiting complete.        ${RESET_FORMAT}\n" # Clear the line and add newline

echo "${YELLOW_TEXT}   Creating backend service 'my-backend-service'...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "backends": [
         {
           "balancingMode": "UTILIZATION",
           "capacityScaler": 1,
           "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION"'/instanceGroups/my-managed-instance-group",
           "maxUtilization": 0.8
         }
       ],
       "connectionDraining": {
         "drainingTimeoutSec": 300
       },
       "description": "",
       "enableCDN": false,
       "healthChecks": [
         "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/my-health-check"
       ],
       "ipAddressSelectionPolicy": "IPV4_ONLY",
       "loadBalancingScheme": "EXTERNAL_MANAGED",
       "localityLbPolicy": "ROUND_ROBIN",
       "logConfig": {
         "enable": false
       },
       "name": "my-backend-service",
       "portName": "http",
       "protocol": "HTTP",
       "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service",
       "sessionAffinity": "NONE",
       "timeoutSec": 30
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/backendServices"

echo "${YELLOW_TEXT}   Waiting 60 seconds...${RESET_FORMAT}"
for i in $(seq 60 -1 1); do
  printf "\r${YELLOW_TEXT}   %2d seconds remaining...${RESET_FORMAT}" "$i"
  sleep 1
done
printf "\r${YELLOW_TEXT}   Waiting complete.        ${RESET_FORMAT}\n" # Clear the line and add newline

echo "${YELLOW_TEXT}   Applying security policy to backend service...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "securityPolicy": "projects/'"$DEVSHELL_PROJECT_ID"'/global/securityPolicies/default-security-policy-for-backend-service-my-backend-service"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/my-backend-service/setSecurityPolicy"

echo "${YELLOW_TEXT}   Waiting 60 seconds...${RESET_FORMAT}"
for i in $(seq 60 -1 1); do
  printf "\r${YELLOW_TEXT}   %2d seconds remaining...${RESET_FORMAT}" "$i"
  sleep 1
done
printf "\r${YELLOW_TEXT}   Waiting complete.        ${RESET_FORMAT}\n" # Clear the line and add newline
echo "${GREEN_TEXT}✅ Backend service and security policies configured.${RESET_FORMAT}"
echo

echo "${BLUE_TEXT}${BOLD_TEXT}🗺️ Step 9: Setting up URL maps, target proxies, and forwarding rules for the load balancer...${RESET_FORMAT}"
echo "${BLUE_TEXT}   Creating URL map 'my-load-balancer'...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/my-backend-service",
       "name": "my-load-balancer"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps"

echo "${BLUE_TEXT}   Waiting 30 seconds...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  printf "\r${BLUE_TEXT}   %2d seconds remaining...${RESET_FORMAT}" "$i"
  sleep 1
done
printf "\r${BLUE_TEXT}   Waiting complete.        ${RESET_FORMAT}\n" # Clear the line and add newline

echo "${BLUE_TEXT}   Creating target HTTP proxy 'my-load-balancer-target-proxy'...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "name": "my-load-balancer-target-proxy",
       "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/my-load-balancer"
     }' \
     "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"

echo "${BLUE_TEXT}   Waiting 90 seconds...${RESET_FORMAT}"
for i in $(seq 90 -1 1); do
  printf "\r${BLUE_TEXT}   %2d seconds remaining...${RESET_FORMAT}" "$i"
  sleep 1
done
printf "\r${BLUE_TEXT}   Waiting complete.        ${RESET_FORMAT}\n" # Clear the line and add newline

echo "${BLUE_TEXT}   Creating forwarding rule 'my-load-balancer-forwarding-rule'...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "IPAddress": "projects/'"$DEVSHELL_PROJECT_ID"'/global/addresses/my-cert",
       "IPProtocol": "TCP",
       "loadBalancingScheme": "EXTERNAL_MANAGED",
       "name": "my-load-balancer-forwarding-rule",
       "networkTier": "PREMIUM",
       "portRange": "80",
       "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/my-load-balancer-target-proxy"
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"

echo "${BLUE_TEXT}   Waiting 30 seconds...${RESET_FORMAT}"
for i in $(seq 30 -1 1); do
  printf "\r${BLUE_TEXT}   %2d seconds remaining...${RESET_FORMAT}" "$i"
  sleep 1
done
printf "\r${BLUE_TEXT}   Waiting complete.        ${RESET_FORMAT}\n" # Clear the line and add newline

echo "${BLUE_TEXT}   Setting named ports for the instance group...${RESET_FORMAT}"
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -d '{
       "namedPorts": [
         {
           "name": "http",
           "port": 80
         }
       ]
     }' \
     "https://compute.googleapis.com/compute/beta/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/instanceGroups/my-managed-instance-group/setNamedPorts"

echo "${GREEN_TEXT}✅ Load balancer components created and configured.${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}📝 Step 11: Generating the 'details.json' file with your email...${RESET_FORMAT}"
echo -e "\n"
EMAIL="$(gcloud config get-value core/account)"
cat > details.json << EOF
  App name: IAP Example
  Developer contact email: $EMAIL
EOF
echo "${GREEN_TEXT}✅ 'details.json' created successfully.${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}📄 Step 12: Displaying the content of 'details.json'...${RESET_FORMAT}"
cat details.json
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}🎥         NOW FOLLOW VIDEO STEPS         🎥${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}🔗 Step 10: Important Links for Next Steps:${RESET_FORMAT}"
echo "${MAGENTA_TEXT}   Configure the OAuth consent screen here:${RESET_FORMAT} ${UNDERLINE_TEXT}https://console.cloud.google.com/auth/overview?project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo
echo "${CYAN_TEXT}   Set up Identity-Aware Proxy (IAP) here:${RESET_FORMAT} ${UNDERLINE_TEXT}https://console.cloud.google.com/security/iap?tab=applications&project=$DEVSHELL_PROJECT_ID${RESET_FORMAT}"
echo
echo
echo -e "${CYAN_TEXT}${BOLD_TEXT}👤 Service Account Email: $PROJECT_NUMBER-compute@developer.gserviceaccount.com${RESET_FORMAT}"
echo

echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 If you found this helpful, please subscribe to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
