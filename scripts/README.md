# Configure System

Downlaod and extract the qubinode-installer as a non root user.

```
cd $HOME
wget https://github.com/Qubinode/qubinode-installer/archive/master.zip
unzip master.zip
rm master.zip
mv qubinode-installer-master qubinode-installer
```

### Run the qubinode installer to setup the host
```
cd ~/qubinode-installer
./qubinode-installer -m setup
./qubinode-installer -m rhsm
./qubinode-installer -m ansible
./qubinode-installer -m host
```

### Create pull secret and api token
* Get an Offline Token: https://access.redhat.com/management/api
* pull secret https://console.redhat.com/openshift/install/metal/installer-provisioned
```
vim ~/pull-secret.txt
vim ~/token.txt
```

### Clone ocp4-ai-svc-libvirt
```
cd $HOME
git clone https://github.com/tosin2013/ocp4-ai-svc-libvirt.git
```

### Install Requirements 
```
cd ocp4-ai-svc-libvirt/ansible

ansible-galaxy collection install -r requirements.yml
```

### Create assisted-installer config
```
cp example_vars/cluster-config.yaml vars/

cat >vars/assisted-service.yaml<<EOF
---
### This file contains the details for what OCP 4 Assisted Installer endpoint will be coordinated with
# assisted_service_fqdn: api.openshift.com or your custom assisted-installer FQDN
assisted_service_fqdn: api.openshift.com
assisted_service_port: 443
assisted_service_transport: https
assisted_service_authentication: bearer-token
assisted_service_authentication_api_bearer_token: $(cat ~/token.txt)


################################################### DO NOT EDIT PAST THIS LINE
assisted_service_api_base: /api/assisted-install/v1
assisted_service_endpoint: "{{ assisted_service_transport }}://{{ assisted_service_fqdn }}:{{ assisted_service_port }}{{ assisted_service_api_base }}"
EOF
```


### update the file paths for vms
```
# vars/libvirt-config.yaml
######################### Storage Options
libvirt_base_iso_path: /var/lib/libvirt/images
libvirt_base_vm_path: /var/lib/libvirt/images
```

### update libvirt-config.yaml networking 
```
######################### Local libvirt options
libvirt_uri: "qemu:///system"
libvirt_network:
  type: bridge
  name: qubibr0
  model: virtio
```

### Copy and configure cluster-config.yaml
```
 cp example_vars/cluster-config.yaml vars/
```

### update the following 
```
vim  vars/cluster-config.yaml

cluster_version: 4.9

cluster_name:
cluster_domain: 



################################################## Cluster Networking
# cluster_network_type = Default, Cilium, or Calico (TODO, only Default and Calico work atm)
cluster_network_type: Default
# cluster_api_vip: an IP or "auto"
cluster_api_vip: 192.168.2.221
# cluster_load_balancer_vip: an IP or "auto"
cluster_load_balancer_vip: 192.168.2.222
# cluster_node_cidr: A CIDR definition or "auto"
cluster_node_cidr: 192.168.2.0/24

cluster_node_network_static_dns_servers:
  - 192.168.2.10
  - 1.1.1.1

Cluster ip addresses

cluster_network_cidr: 192.168.2.0/24
cluster_network_host_prefix: 23
```

### Testing: update kvm_libvirt_vm.xml.j2
```
vim templates/kvm_libvirt_vm.xml.j2
    <type arch='x86_64' machine='pc-q35-rhel8.4.0'>hvm</type> #     <type arch='x86_64' machine='pc-q35-rhel8.2.0'>hvm</type>
 was tested
```


### Add api and load balancer entries to DNS

### Run ansible playbook 
```
sudo ansible-playbook -e "vars/cluster-config.yaml" bootstrap.yaml  -vvv
```

## To destroy cluster 
```
sudo ansible-playbook -e "vars/cluster-config.yaml" destroy.yaml -vvv
```
