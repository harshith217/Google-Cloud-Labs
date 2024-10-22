read -p "Enter the main region (e.g., us-east4): " REGION
read -p "Enter the second region (e.g., europe-west1): " REGION2
read -p "Enter the third region (e.g., europe-west4): " REGION3


gcloud config set compute/region "$REGION"
export REGION=$(gcloud config get-value compute/region)
gcloud config set compute/zone "${REGION}-c"
export ZONE=$(gcloud config get-value compute/zone)


gcloud compute networks create taw-custom-network --subnet-mode=custom


gcloud compute networks subnets create subnet-$REGION --network=taw-custom-network --region=$REGION --range=10.0.0.0/16
gcloud compute networks subnets create subnet-$REGION2 --network=taw-custom-network --region=$REGION2 --range=10.1.0.0/16
gcloud compute networks subnets create subnet-$REGION3 --network=taw-custom-network --region=$REGION3 --range=10.2.0.0/16


gcloud compute firewall-rules create nw101-allow-http --network=taw-custom-network --allow tcp:80 --target-tags=http --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create nw101-allow-icmp --network=taw-custom-network --allow icmp --target-tags=rules --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create nw101-allow-internal --network=taw-custom-network --allow tcp:0-65535,udp:0-65535,icmp --source-ranges=10.0.0.0/16,10.1.0.0/16,10.2.0.0/16
gcloud compute firewall-rules create nw101-allow-ssh --network=taw-custom-network --allow tcp:22 --target-tags=ssh --source-ranges=0.0.0.0/0
gcloud compute firewall-rules create nw101-allow-rdp --network=taw-custom-network --allow tcp:3389 --source-ranges=0.0.0.0/0
