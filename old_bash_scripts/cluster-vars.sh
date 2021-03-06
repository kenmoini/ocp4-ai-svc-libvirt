#!/bin/bash

#set -x
#set -e

if [ -f ".cluster.nfo" ]; then
  CLUSTER_ID=$(cat .cluster.nfo)
fi

ASSISTED_SERVICE_IP="assisted-installer.kemo.labs"
ASSISTED_SERVICE_PORT="8090"

# CLUSTER_TYPE can be: Standard (HA CP+App Nodes), SNO (Single Node OpenShift)
CLUSTER_TYPE="Standard"

# CLUSTER_NET_TYPE = Default, or Calico
CLUSTER_NET_TYPE="Default"

CLUSTER_NAME="core-ocp"
CLUSTER_DOMAIN="kemo.labs"

CLUSTER_API_VIP="192.168.42.76" # an IP or "auto"
CLUSTER_LOAD_BALANCER_VIP="192.168.42.77" # an IP or "auto"
CLUSTER_MACHINE_CIDR="192.168.42.0/24" # A CIDR definition or "auto"
CLUSTER_NODE_NETWORK_IPAM="manual" # dhcp or static
CLUSTER_NODE_NETWORK_MANUAL_DNS_SERVERS=("192.168.42.9" "192.168.42.10")
CLUSTER_CIDR_NET="10.128.0.0/14"
CLUSTER_CIDR_SVC="172.30.0.0/16"
CLUSTER_HOST_PFX="23"
CLUSTER_APP_NODE_HT="Enabled"
CLUSTER_APP_NODE_COUNT="3"
CLUSTER_APP_NODE_CPU_SOCKETS="1"
CLUSTER_APP_NODE_CPU_CORES="8"
CLUSTER_APP_NODE_RAM_GB="32"
CLUSTER_APP_NODE_DISK_GB="60"
CLUSTER_CONTROL_PLANE_HT="Enabled"
CLUSTER_CONTROL_PLANE_COUNT="3"
CLUSTER_CONTROL_PLANE_CPU_SOCKETS="1"
CLUSTER_CONTROL_PLANE_CPU_CORES="4"
CLUSTER_CONTROL_PLANE_RAM_GB="16"
CLUSTER_CONTROL_PLANE_DISK_GB="60"

if [ ! -f "$HOME/.ssh/MasterKemoKey.pub-ah" ]; then
  echo "SSH Key does not exist."
  exit
fi
CLUSTER_SSHKEY=$(cat $HOME/.ssh/MasterKemoKey.pub-ah | cut -d ' ' -f 1,2)
TOKEN=""

if [ ! -f "./pull-secret.txt" ]; then
  echo "pull-secret.txt does not exist."
  exit
fi
PULL_SECRET=$(cat pull-secret.txt | jq -R .)

# INFRASTRUCTURE_LAYER Options: (blank, no infrastructure created), libvirt, or libvirt-local
INFRASTRUCTURE_LAYER="libvirt-local"

################### General libvirt Options
LIBVIRT_NETWORK="bridge=containerLANbr0,model=virtio"
################### Remote libvirt Options
LIBVIRT_ENDPOINT="raza.kemo.labs"
LIBVIRT_TRANSPORT_TYPE="qemu+ssh"
LIBVIRT_USER="root"

#####################################################################
# No need to edit past these lines
#####################################################################

LOG_FILE="./.local-ocp-ai.log"

if [[ $INFRASTRUCTURE_LAYER = "libvirt" ]]; then
  LIBVIRT_URI="${LIBVIRT_TRANSPORT_TYPE}://${LIBVIRT_USER}@${LIBVIRT_ENDPOINT}/system?no_verify=1&socket=/var/run/libvirt/libvirt-sock"
fi
if [[ $INFRASTRUCTURE_LAYER = "libvirt-local" ]]; then
  LIBVIRT_URI="qemu:///system"
fi

LIBVIRT_MAC_PREFIX="54:52:00:42:69:"
LIBVIRT_REMOTE_ISO_PATH="/mnt/nvme_7TB/nfs/isos"
LIBVIRT_VM_PATH="/mnt/nvme_7TB/nfs/vms/raza"
LIBVIRT_LIKE_OPTIONS="--connect=${LIBVIRT_URI} -v --memballoon none --cpu host-passthrough --autostart --noautoconsole --virt-type kvm --features kvm_hidden=on --controller type=scsi,model=virtio-scsi --cdrom=${LIBVIRT_REMOTE_ISO_PATH}/ai-liveiso-$CLUSTER_ID.iso  --os-variant=fedora-coreos-stable --autostart --events on_reboot=restart,on_poweroff=preserve --graphics vnc,listen=${LIBVIRT_ENDPOINT},tlsport=,defaultMode='insecure' --network ${LIBVIRT_NETWORK}"

if [[ $CLUSTER_TYPE = "Standard" ]]; then
  CLUSTER_VERSION="4.7.9"
  CLUSTER_IMAGE="quay.io/openshift-release-dev/ocp-release:4.7.9-x86_64"
fi

if [[ $CLUSTER_TYPE = "SNO" ]]; then
  CLUSTER_VERSION="4.8.0-rc.0"
  CLUSTER_IMAGE="quay.io/openshift-release-dev/ocp-release:4.8.0-rc.0-x86_64"
fi

function checkForProgramAndExit() {
    command -v $1 > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        printf '%-72s %-7s\n' $1 "PASSED!";
    else
        printf '%-72s %-7s\n' $1 "FAILED!";
        exit 1
    fi
}

echo -e "\n===== Checking for needed programs..."
checkForProgramAndExit curl
checkForProgramAndExit jq
checkForProgramAndExit virt-install

echo -e "===== Preflight passed...\n"
