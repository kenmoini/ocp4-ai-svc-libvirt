#!/bin/bash

#set -x
#set -e

source ./cluster-vars.sh

LOOP_ON="true"
CYCLE_TIME_IN_SECONDS="10"
CLUSTER_CONSOLE_URL=""
CLUSTER_CONSOLE_KUBEADMIN_USERNAME=""
CLUSTER_CONSOLE_KUBEADMIN_PASSWORD=""

echo "Checking for git..."
checkForProgramAndExit git

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function logIntoCluster() {
  # Set the Kubeconfig file
  # Query the Cluster for Kubeconfig data
  curl -s \
    --header "Content-Type: application/octet-stream" \
    --header "Accept: application/octet-stream" \
    --request GET \
  "http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/downloads/kubeconfig" > ".kubeconfig.${CLUSTER_ID}"
  eval $(parse_yaml ".kubeconfig.${CLUSTER_ID}")

  # Query the Cluster for kubeadmin password
  CLUSTER_KUBEADMIN_REQ=$(curl -s \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --request GET \
  "http://$ASSISTED_SERVICE_IP:$ASSISTED_SERVICE_PORT/api/assisted-install/v1/clusters/$CLUSTER_ID/credentials")

  CLUSTER_CONSOLE_URL=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.console_url')
  CLUSTER_CONSOLE_KUBEADMIN_USERNAME=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.username')
  CLUSTER_CONSOLE_KUBEADMIN_PASSWORD=$(printf '%s' "$CLUSTER_KUBEADMIN_REQ" | jq -r '.password')

  echo "===== Connecting to: $clusters__server ..."

  command -v oc > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "===== OpenShift CLI (oc) in PATH, using local copy...";
  else
    echo "===== OpenShift CLI (oc) not found in PATH, downloading copy now...";
    mkdir .tmpbin

    # Detect OS Type
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     machine=linux;;
        Darwin*)    machine=mac;;
        *)          machine="UNKNOWN:${unameOut}"
    esac

    curl -sL  "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${CLUSTER_VERSION}/openshift-client-${machine}.tar.gz" -o .tmpbin/oc.tar.gz
    cd .tmpbin
    tar zxvf oc.tar.gz
    chmod +x oc
    cd ..
    PATH="$PATH:$PWD/tmpbin"
  fi

  # Actually Log into the Cluster
  oc login $clusters__server --password="${CLUSTER_CONSOLE_KUBEADMIN_PASSWORD}" --username="${CLUSTER_CONSOLE_KUBEADMIN_USERNAME}" --insecure-skip-tls-verify=true
}

function runClusterConfiguration() {
  logIntoCluster

  # Clone down git repo
  git clone https://github.com/kenmoini/homelab
  CUR_DIR=$PWD
  cd homelab/openshift-quickstarts/cluster-init/

  cd matrix-login
  ./run.sh && cd ..

  cd nfs-registry
  ./run.sh && cd ..

  cd nfs-storageclass
  ./run.sh && cd ..

  # return and clean up
  cd $CUR_DIR
  rm -rf homelab
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
    echo -e "===== Cluster has finished installing...running cluster configuration now...\n"
    runClusterConfiguration
  else
    echo "===== Waiting for cluster to be fully installed and ready...waiting $CYCLE_TIME_IN_SECONDS seconds..."
    sleep $CYCLE_TIME_IN_SECONDS
  fi

done

