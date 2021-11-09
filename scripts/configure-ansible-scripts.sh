#!/bin/bash


~/pull-secret.txt
~/token.txt

cd ocp4-ai-svc-libvirt/ansible

ansible-galaxy collection install -r requirements.yml

cp example_vars/cluster-config.yaml vars/
#cp example_vars/assisted-service.yaml vars/


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

# vars/libvirt-config.yaml
######################### Storage Options
#libvirt_base_iso_path: /mnt/nvme_2TB/isos
#libvirt_base_vm_path: /mnt/nvme_2TB/VMs


cat >inventory.local<<EOF
[libvirtHosts]
localhost
EOF

cd ~/homelab/ansible-collections/

sudo ansible-playbook -i inventory.local deploy-libvirt.yml

cd ~/ocp4-ai-svc-libvirt/ansible

sudo ansible-playbook -e "vars/cluster-config.yaml" bootstrap.yaml

#cluster_name: play-ocp                                                                                                                                                                                                                    
#cluster_domain: kemo.labs 
#   - kemo.labs