# OpenShift Container Platform v4 - Assisted Installer Service Helper for Libvirt

This repository provides the local coordination required to utilize the OCP Assisted Installer service to deploy on Libvirt.

## Deploying the OCP 4 Assisted Installer service

Before you can use the resources in this repository, you need to have the OCP AI Service already running.  To do so, you can run the following so long as Podman is installed on your service host:

```bash
#!/bin/bash

# Variables
CONTAINER_NAME="caas-assisted-installer"
NETWORK_NAME="lanBridge"
IP_ADDRESS="192.168.42.70"

########################################################################
RHCOS_VERSION="latest"

# BASE_OS_IMAGE matches current release, which is 4.7.x
BASE_OS_IMAGE=https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.7/${RHCOS_VERSION}/rhcos-live.x86_64.iso

# For 4.8.0-fc.3 SNO deployments, replace BASE_OS_IMAGE with the following URL:
# BASE_OS_IMAGE=https://mirror.openshift.com/pub/openshift-v4/amd64/dependencies/rhcos/pre-release/latest-4.8/rhcos-4.8.0-fc.4-x86_64-live.x86_64.iso

OAS_UI_IMAGE=quay.io/ocpmetal/ocp-metal-ui:latest
OAS_DB_IMAGE=quay.io/ocpmetal/postgresql-12-centos7
OAS_IMAGE=quay.io/ocpmetal/assisted-service:latest
COREOS_INSTALLER=quay.io/coreos/coreos-installer:v0.9.1

OAS_HOSTDIR=/opt/service-containers/caas-assisted-installer
OAS_ENV_FILE=${OAS_HOSTDIR}/volumes/opt/onprem-environment
OAS_UI_CONF=${OAS_HOSTDIR}/volumes/opt/nginx-ui.conf
OAS_LIVE_CD=${OAS_HOSTDIR}/local-store/rhcos-live.x86_64.iso
OAS_COREOS_INSTALLER=${OAS_HOSTDIR}/local-store/coreos-installer

SERVICE_FQDN="assisted-installer.kemo.labs"

########################################################################

# Download RHCOS live CD
if [[ ! -f $OAS_LIVE_CD ]]; then
    echo "Base Live ISO not found. Downloading RHCOS live CD from $BASE_OS_IMAGE"
    curl -L $BASE_OS_IMAGE -o $OAS_LIVE_CD
fi

# Download RHCOS installer
if [[ ! -f $OAS_COREOS_INSTALLER ]]; then
  podman run --privileged -it --rm \
    -v ${OAS_HOSTDIR}/local-store:/data \
    -w /data \
    --entrypoint /bin/bash \
    ${COREOS_INSTALLER} \
    -c 'cp /usr/sbin/coreos-installer /data/coreos-installer'
fi

# Prepare for persistence
# NOTE: Make sure to delete this directory if persistence is not desired for a new environment!
mkdir -p ${OAS_HOSTDIR}/data/postgresql
chown -R 26 ${OAS_HOSTDIR}/data/postgresql/

# Create Pod and deploy containers
echo -e "Deploying Pod...\n"
podman pod create --name "${CONTAINER_NAME}" --network "${NETWORK_NAME}" --ip "${IP_ADDRESS}" -p 8000:8000 -p 8090:8090 -p 8888:8080

sleep 3

# Deploy database
echo -e "Deploying Database...\n"
nohup podman run -dt --pod "${CONTAINER_NAME}" --env-file $OAS_ENV_FILE \
  --volume ${OAS_HOSTDIR}/data/postgresql:/var/lib/pgsql:z \
  --name db $OAS_DB_IMAGE

sleep 3

# Deploy Assisted Service
echo -e "Deploying Assisted Service...\n"
nohup podman run -dt --pod "${CONTAINER_NAME}" \
  -v ${OAS_LIVE_CD}:/data/livecd.iso:z \
  -v ${OAS_COREOS_INSTALLER}:/data/coreos-installer:z \
  --env-file $OAS_ENV_FILE \
  --env DUMMY_IGNITION=False \
  --restart always \
  --name installer $OAS_IMAGE

sleep 45

# Deploy UI
echo -e "Deploying UI...\n"
nohup podman run -dt --pod "${CONTAINER_NAME}" --env-file $OAS_ENV_FILE \
  -v ${OAS_UI_CONF}:/opt/bitnami/nginx/conf/server_blocks/nginx.conf:z \
  --name ui $OAS_UI_IMAGE
```

## Creating an OpenShift 4 Cluster on Libvirt via the AI Service

### Get a Pull Secret

Before doing installing OpenShift you'll need a ***Pull Secret*** - you can download one here: https://cloud.redhat.com/openshift/install/pull-secret

Download the Pull Secret as a text file and place it in this directory as `pull-secret.txt` - alternatively, redefine where the Pull Secret is located by modifying `cluster-vars.sh` around lines 48-52: https://github.com/kenmoini/ocp4-ai-svc-libvirt/blob/main/cluster-vars.sh#L48-L52

### SSH Key

To deploy the OpenShift nodes you'll need an SSH Key which will allow direct connection to the nodes in the case of emergency or when needing to debug.

Modify the `cluster-vars.sh` file around lines 41-45 to define where your SSH Public Key is located, represented as the variable `CLUSTER_SSHKEY`: https://github.com/kenmoini/ocp4-ai-svc-libvirt/blob/main/cluster-vars.sh#L41-L45

### Plan the Infrastructure

Considerations must still be made just like any other OpenShift install - you'll likely need two VIPs for the API endpoint and Load Balancer Ingress, shared storage, etc.  Please ensure all requirements are accounted for: https://access.redhat.com/documentation/en-us/openshift_container_platform/4.7/

### Modify the `cluster-vars.sh` file for your environment

Next you'll need to align the desired specifications of your OpenShift cluster and Libvirt host in the `cluster-vars.sh` file.

### Modify the Bootstrap script

To pull everything together, the `bootstrap.sh` file will:

1. Create and Configure the OpenShift Cluster in the Assisted Installer Service
2. Download the ISO for the cluster
3. Provision the Libvirt VMs & wait 90 seconds for them to communicate with the AI Service
4. Perform Host Name and Host Role configuration as well as setting VIPs
5. Kick off the Cluster Installation
6. Wait for the VMs to power off and boot them again (hacky bypass for a bug in Libvirt which doesn't respect on_restart events)
7. Apply a standard post-cluster installation configuration, such as a Matrix-style log in screen, NFS provisioners, and so on.

The last step, #7 which applies the post-cluster installation is likely something you'll need to modify since your NFS storage (if you have it or intend to use it for OCP), is likely different than mine.

## Helper Scripts

To aid with the use of a cluster created via the AI Service, there are additional scripts that can be found in this repository:

- `api-ocp-get-cluster-info.sh` - Presents the general cluster information & current configuration
- `api-ocp-get-kubeadmin.sh` - A script to echo out the kubeadmin password once the cluster has finished installing.  The source also contains the API call to obtain the kubeconfig file as well.
- `api-ocp-reset-cluster.sh` - This will reset a failed cluster installation - hosts still need to be removed manually