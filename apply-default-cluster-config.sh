#!/bin/bash

#set -x
#set -e

source ./cluster-vars.sh

LOOP_ON="true"
CYCLE_TIME_IN_SECONDS="10"

function runClusterConfiguration() {
  # Set the Kubeconfig file
  # Query the Cluster for Kubeconfig data
  curl -s \
    --header "Content-Type: application/octet-stream" \
    --header "Accept: application/octet-stream" \
    --request GET \
  "http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/kubeconfig" > ".kubeconfig.${CLUSTER_ID}"

  # Query the Cluster for kubeadmin password
  CLUSTER_KUBEADMIN_REQ=$(curl -s \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/credentials")

  CLUSTER_CONSOLE_URL=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.console_url')
  CLUSTER_CONSOLE_KUBEADMIN_USERNAME=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.username')
  CLUSTER_CONSOLE_KUBEADMIN_PASSWORD=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.password')
  
}

while [ $LOOP_ON = "true" ]; do
  # Query the Assisted Installer Service for Cluster Status
  CLUSTER_INFO_REQ=$(curl -s \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID")
  CLUSTER_STATUS=$(echo $CLUSTER_INFO_REQ | jq -r '.status')

  if [[ $CLUSTER_STATUS = "installed" ]]; then
    LOOP_ON="false"
    echo "Cluster has finished installing...running cluster configuration now..."
    runClusterConfiguration
  else
    echo "Waiting for cluster to be fully installed and ready...waiting $CYCLE_TIME_IN_SECONDS seconds..."
    sleep $CYCLE_TIME_IN_SECONDS
  fi

done

