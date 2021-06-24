#!/bin/bash

#set -x
#set -e

source ./cluster-vars.sh

# Query the Cluster for Kubeconfig data
CLUSTER_KUBECONFIG_REQ=$(curl -s \
  --header "Content-Type: application/octet-stream" \
  --header "Accept: application/octet-stream" \
  --request GET \
"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/kubeconfig")

# Query the Cluster for kubeadmin password
CLUSTER_KUBEADMIN_REQ=$(curl -s \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --request GET \
"http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/credentials")

CLUSTER_CONSOLE_URL=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.console_url')
CLUSTER_CONSOLE_KUBEADMIN_USERNAME=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.username')
CLUSTER_CONSOLE_KUBEADMIN_PASSWORD=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.password')

echo "Username: $CLUSTER_CONSOLE_KUBEADMIN_USERNAME"
echo "Password: $CLUSTER_CONSOLE_KUBEADMIN_PASSWORD"
echo -e "Console URL: $CLUSTER_CONSOLE_URL\n"