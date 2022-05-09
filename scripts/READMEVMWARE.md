# Vmware Sphere deployments

### Optional Configure gozones for DNS
```
$ cd scipts
$ ./gozones.sh
```


date +%s | md5sum | head -c 6 | sed -e 's/\([0-9A-Fa-f]\{2\}\)/\1:/g' -e 's/\(.*\):$/\1/' | sed -e 's/^/00:50:56:/'

### Create Ansible Vault
```
$ cd ansible 
$ ansible-vault create vars/vault.yml
```

> The vault requires the following variables. Adjust the values to suit your environment.
```
---
vcenter_fqdn: "vsphere.example.com"
vcenter_username: "administrator@vsphere.local"
vcenter_password: "changeme"
skip_ssl_validation: true
vsphere_datacenter: "Datacenter"
vsphere_cluster: Cluster
vsphere_datastore: "Datastore"
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
assisted_service_api_base: /api/assisted-install/v2
assisted_service_endpoint: "{{ assisted_service_transport }}://{{ assisted_service_fqdn }}:{{ assisted_service_port }}{{ assisted_service_api_base }}"
EOF
```

### Copy and configure cluster-config.yaml
```
 cp example_vars/cluster-config.yaml vars/
```

### Add api and load balancer entries to DNS

### Run Ansible playbook 
```
sudo ansible-playbook -e "vars/cluster-config.yaml" bootstrap.yaml  --ask-vault-pass  -vvv
```

## To destroy cluster 
```
sudo ansible-playbook -e "vars/cluster-config.yaml" destroy.yaml --ask-vault-pass -vvv
```
