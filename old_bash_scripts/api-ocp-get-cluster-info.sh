#!/bin/bash

#set -x
#set -e

source ./cluster-vars.sh

# Query the Cluster for Information around its composition
CLUSTER_INFO_REQ=$(curl -s \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request GET \
"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID")

echo $CLUSTER_INFO_REQ | python3 -m json.tool