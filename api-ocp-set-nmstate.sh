#!/bin/bash

#set -x
#set -e

source ./cluster-vars.sh

# ====================================================== FUNCTIONS

function generateDNSServerEntries() {
  SPACES=""
  SPACE_COUNT=$1
  for i in "${CLUSTER_NODE_NETWORK_MANUAL_DNS_SERVERS[@]}"; do 
  while [ $SPACE_COUNT -gt 0 ]; 
  do 
    SPACES="$SPACES "
    SPACE_COUNT=$(($SPACE_COUNT-1))
  done
   echo "${SPACES}- $i"
  done
}

function generateNMStateYAML() {
cat <<EOF
dns-resolver:
  config:
    server:
$(generateDNSServerEntries 4)
interfaces:
- ipv4:
    address:
    - ip: 192.168.126.30
      prefix-length: 24
    dhcp: false
    enabled: true
  name: eth0
  state: up
  type: ethernet
routes:
  config:
  - destination: 0.0.0.0/0
    next-hop-address: 192.168.126.1
    next-hop-interface: eth0
    table-id: 254
EOF
}

if [[ $CLUSTER_NODE_NETWORK_IPAM = "dhcp" ]]; then
  echo -e "===== Node Network Mode set to DHCP, skipping static networking...\n"
else
  echo -e "===== Node Network Mode set to Manual, setting static networking...\n"

generateNMStateYAML

# Query the Cluster for Information around its composition
CLUSTER_INFO_REQ=$(curl -s \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request GET \
"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID")

#echo $CLUSTER_INFO_REQ | python3 -m json.tool

fi