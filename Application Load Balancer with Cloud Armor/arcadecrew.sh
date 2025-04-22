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
echo "${CYAN_TEXT}${BOLD_TEXT}          INITIATING EXECUTION     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the first REGION: ${RESET_FORMAT}" REGION1
echo "${GREEN_TEXT}${BOLD_TEXT}First REGION set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$REGION1${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the second REGION: ${RESET_FORMAT}" REGION2
echo "${GREEN_TEXT}${BOLD_TEXT}Second REGION set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$REGION2${RESET_FORMAT}"

read -p "${YELLOW_TEXT}${BOLD_TEXT}Enter the VM_ZONE: ${RESET_FORMAT}" VM_ZONE
echo "${GREEN_TEXT}${BOLD_TEXT}VM_ZONE set to:${RESET_FORMAT} ${CYAN_TEXT}${BOLD_TEXT}$VM_ZONE${RESET_FORMAT}"

# Export variables after collecting input
export REGION1 REGION2 VM_ZONE

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 1:${RESET_FORMAT} ${MAGENTA_TEXT}Creating firewall rules to allow HTTP traffic and health checks...${RESET_FORMAT}"
gcloud compute firewall-rules create default-allow-http --project=$DEVSHELL_PROJECT_ID --direction=INGRESS --priority=1000 --network=default --source-ranges=0.0.0.0/0 --target-tags=http-server --action=ALLOW --rules=tcp:80 && gcloud compute firewall-rules create default-allow-health-check --project=$DEVSHELL_PROJECT_ID --direction=INGRESS --priority=1000 --network=default --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server --action=ALLOW --rules=tcp

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 2:${RESET_FORMAT} ${CYAN_TEXT}Creating instance templates and managed instance groups in your selected regions...${RESET_FORMAT}"

gcloud beta compute instance-groups managed create $REGION2-mig --project=$DEVSHELL_PROJECT_ID --base-instance-name=$REGION2-mig --size=1 --template=$REGION2-template --region=$REGION2 --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair && gcloud beta compute instance-groups managed set-autoscaling $REGION2-mig --project=$DEVSHELL_PROJECT_ID --region=$REGION2 --cool-down-period=45 --max-num-replicas=2 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 3:${RESET_FORMAT} ${GREEN_TEXT}Fetching your GCP Project ID and authentication token...${RESET_FORMAT}"

DEVSHELL_PROJECT_ID=$(gcloud config get-value project)

TOKEN=$(gcloud auth application-default print-access-token)

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 4:${RESET_FORMAT} ${MAGENTA_TEXT}Creating a TCP health check for your backend instances...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "checkIntervalSec": 5,
        "description": "",
        "healthyThreshold": 2,
        "logConfig": {
            "enable": false
        },
        "name": "http-health-check",
        "tcpHealthCheck": {
            "port": 80,
            "proxyHeader": "NONE"
        },
        "timeoutSec": 5,
        "type": "TCP",
        "unhealthyThreshold": 2
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/healthChecks"

sleep 30

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 5:${RESET_FORMAT} ${CYAN_TEXT}Configuring backend services for load balancing...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "backends": [
            {
                "balancingMode": "RATE",
                "capacityScaler": 1,
                "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION1"'/instanceGroups/'"$REGION1-mig"'",
                "maxRatePerInstance": 50
            },
            {
                "balancingMode": "UTILIZATION",
                "capacityScaler": 1,
                "group": "projects/'"$DEVSHELL_PROJECT_ID"'/regions/'"$REGION2"'/instanceGroups/'"$REGION2-mig"'",
                "maxRatePerInstance": 80,
                "maxUtilization": 0.8
            }
        ],
        "cdnPolicy": {
            "cacheKeyPolicy": {
                "includeHost": true,
                "includeProtocol": true,
                "includeQueryString": true
            },
            "cacheMode": "CACHE_ALL_STATIC",
            "clientTtl": 3600,
            "defaultTtl": 3600,
            "maxTtl": 86400,
            "negativeCaching": false,
            "serveWhileStale": 0
        },
        "compressionMode": "DISABLED",
        "connectionDraining": {
            "drainingTimeoutSec": 300
        },
        "description": "",
        "enableCDN": true,
        "healthChecks": [
            "projects/'"$DEVSHELL_PROJECT_ID"'/global/healthChecks/http-health-check"
        ],
        "loadBalancingScheme": "EXTERNAL",
        "logConfig": {
            "enable": true,
            "sampleRate": 1
        },
        "name": "http-backend"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices"

sleep 60

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 6:${RESET_FORMAT} ${MAGENTA_TEXT}Setting up URL maps for routing traffic...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "defaultService": "projects/'"$DEVSHELL_PROJECT_ID"'/global/backendServices/http-backend",
        "name": "http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/urlMaps"

sleep 30

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 7:${RESET_FORMAT} ${CYAN_TEXT}Creating target HTTP proxies for your load balancer...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "http-lb-target-proxy",
        "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"

sleep 30

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 8:${RESET_FORMAT} ${GREEN_TEXT}Creating forwarding rules for IPv4 traffic...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "IPProtocol": "TCP",
        "ipVersion": "IPV4",
        "loadBalancingScheme": "EXTERNAL",
        "name": "http-lb-forwarding-rule",
        "networkTier": "PREMIUM",
        "portRange": "80",
        "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"

sleep 30

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 9:${RESET_FORMAT} ${CYAN_TEXT}Creating a second target HTTP proxy for IPv6...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "name": "http-lb-target-proxy-2",
        "urlMap": "projects/'"$DEVSHELL_PROJECT_ID"'/global/urlMaps/http-lb"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/targetHttpProxies"

sleep 30

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 10:${RESET_FORMAT} ${GREEN_TEXT}Creating forwarding rules for IPv6 traffic...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "IPProtocol": "TCP",
        "ipVersion": "IPV6",
        "loadBalancingScheme": "EXTERNAL",
        "name": "http-lb-forwarding-rule-2",
        "networkTier": "PREMIUM",
        "portRange": "80",
        "target": "projects/'"$DEVSHELL_PROJECT_ID"'/global/targetHttpProxies/http-lb-target-proxy-2"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/forwardingRules"

sleep 30

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 11:${RESET_FORMAT} ${CYAN_TEXT}Assigning named ports to your instance groups...${RESET_FORMAT}"

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "namedPorts": [
            {
                "name": "http",
                "port": 80
            }
        ]
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION2/instanceGroups/$INSTANCE_NAME_2/setNamedPorts"

sleep 30

curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
        "namedPorts": [
            {
                "name": "http",
                "port": 80
            }
        ]
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION1/instanceGroups/$INSTANCE_NAME/setNamedPorts"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 12:${RESET_FORMAT} ${MAGENTA_TEXT}Creating a Siege VM for load testing...${RESET_FORMAT}"

gcloud compute instances create siege-vm --project=$DEVSHELL_PROJECT_ID --zone=$VM_ZONE --machine-type=e2-medium --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --metadata=enable-oslogin=true --maintenance-policy=MIGRATE --provisioning-model=STANDARD --create-disk=auto-delete=yes,boot=yes,device-name=siege-vm,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230629,mode=rw,size=10,type=projects/$DEVSHELL_PROJECT_ID/zones/us-central1-c/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

sleep 60

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 13:${RESET_FORMAT} ${CYAN_TEXT}Retrieving the external IP address of your Siege VM...${RESET_FORMAT}"

export EXTERNAL_IP=$(gcloud compute instances  describe siege-vm --zone=$VM_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

sleep 30

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 14:${RESET_FORMAT} ${GREEN_TEXT}Creating a Cloud Armor security policy to deny traffic from the Siege VM...${RESET_FORMAT}"

curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d '{
        "adaptiveProtectionConfig": {
            "layer7DdosDefenseConfig": {
                "enable": false
            }
        },
        "description": "",
        "name": "denylist-siege",
        "rules": [
            {
                "action": "deny(403)",
                "description": "",
                "match": {
                    "config": {
                        "srcIpRanges": [
                             "'"${EXTERNAL_IP}"'"
                        ]
                    },
                    "versionedExpr": "SRC_IPS_V1"
                },
                "preview": false,
                "priority": 1000
            },
            {
                "action": "allow",
                "description": "Default rule, higher priority overrides it",
                "match": {
                    "config": {
                        "srcIpRanges": [
                            "*"
                        ]
                    },
                    "versionedExpr": "SRC_IPS_V1"
                },
                "preview": false,
                "priority": 2147483647
            }
        ],
        "type": "CLOUD_ARMOR"
    }' \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/securityPolicies"

sleep 30

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Step 15:${RESET_FORMAT} ${MAGENTA_TEXT}Attaching the Cloud Armor policy to your backend service...${RESET_FORMAT}"

curl -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d "{
        \"securityPolicy\": \"projects/$DEVSHELL_PROJECT_ID/global/securityPolicies/denylist-siege\"
    }" \
    "https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/global/backendServices/http-backend/setSecurityPolicy"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}Step 16:${RESET_FORMAT} ${CYAN_TEXT}Fetching the external IP address of your load balancer...${RESET_FORMAT}"

LB_IP_ADDRESS=$(gcloud compute forwarding-rules describe http-lb-forwarding-rule --global --format="value(IPAddress)")

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Step 17:${RESET_FORMAT} ${GREEN_TEXT}Running a load test from the Siege VM...${RESET_FORMAT}"

gcloud compute ssh --zone "$VM_ZONE" "siege-vm" --project "$DEVSHELL_PROJECT_ID" --quiet --command "sudo apt-get -y install siege && export LB_IP=$LB_IP_ADDRESS && siege -c 150 -t 120s http://\$LB_IP"

echo
echo "${RED_TEXT}${BOLD_TEXT}Don't forget to subscribe to my Channel (Arcade Crew):${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
