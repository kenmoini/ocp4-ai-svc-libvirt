# OpenShift 4 Assisted Installer on Libvirt/KVM

This set of resources handles an idempotent way to deploy OpenShift via an Assisted Installer service onto a Libvirt/KVM host.

## Operations

What this Ansible content will do is the following:

### bootstrap.yaml

1. Do preflight for binaries, create asset generation directory, set HTTP Headers & Authentication
2. Do preflight checks for supported OpenShift versions on the Assisted Installer Service
3. Query the AI Svc, check for existing cluster with the same name
4. Set needed facts, or create a new cluster with new SSH keys
5. Configure cluster on the AI Svc with deployment specs and ISO Params
6. Download the generated ISO, copy to Libvirt ISO Root Path
7. Create Libvirt VMs
8. Wait for the hosts to report into the AI Svc
9. Set Host Names and Roles on the AI Svc
10. Set Network VIPs on the AI Svc
11. Wait for the hosts to be ready
12. [Optional/Dependant/Non-Default] Set Cilium Networking Manifests on the AI Svc
13. [Optional/Dependant/Non-Default] Set Calico Networking Manifests on the AI Svc
14. Start the cluster installation on the AI Svc
15. Wait for the cluster to be fully installed
16. Pull cluster credentials from the AI Svc
17. Perform cluster post-configuration, anything in `post-tasks/`

## Prerequisites

Before using this automation you'll need to set up a few things on the Ansible control node

### [One-time] Installing Libvirt & System Packages

There are a few packages required by the automation functions:

```bash
## Install Libvirt
sudo dnf module -y install virt

## Install supporting packages
sudo dnf install -y jq git curl wget virt-install virt-viewer
```

### [One-time] Installing Pip modules

Some of the Ansible Modules require additional Python Pip modules - install the following:

```bash
## Install Ansible if needed
sudo python3 -m pip install ansible paramiko jmespath

## Install the Kubernetes and OpenShift modules
sudo python3 -m pip install kubernetes openshift

## or...
sudo python3 -m pip install --upgrade -r requirements.txt
```

### [One-time] Installing oc

There are a few Ansible Tasks that use the `command` module to execute commands best/easiest serviced by the `oc` binary - thusly, `oc` needs to be available in the system path

```bash
## Create a binary directory if needed
sudo mkdir -p /usr/local/bin
sudo echo 'export PATH="/usr/local/bin:$PATH"' > /etc/profile.d/usrlibbin.sh
sudo chmod a+x /etc/profile.d/usrlibbin.sh
source /etc/profile.d/usrlibbin.sh

## Download the latest oc binary
mkdir -p /tmp/bindl
cd /tmp/bindl
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar zxvf openshift-client-linux.tar.gz

## Move it to the bin dir
sudo mv kubectl /usr/local/bin
sudo mv oc /usr/local/bin

## Clean up
cd -
rm -rf /tmp/bindl
```

### [One-time] Installing Ansible Collections

In order to run this Playbook you'll need to have the needed Ansible Collections already installed - you can do so easily by running the following command:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Modify the Variables files

- Copy `example_vars/cluster-config.yaml` to the working directory, ideally with a prefix of the cluster name - modify as needed
- Modify the other files in `example_vars/` and copy to `vars/` as you see fit

## Running the Playbook

With the needed variables altered, you can run the Playbook with the following command:

```bash
ansible-playbook -e "@cluster-name.cluster-config.yaml" bootstrap.yaml
```