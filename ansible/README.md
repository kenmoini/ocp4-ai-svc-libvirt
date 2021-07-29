# OpenShift 4 Assisted Installer on Libvirt/KVM

This set of resources handles an idempotent way to deploy OpenShift via an Assisted Installer service onto a Libvirt/KVM host.

## Installing Ansible Collections

In order to run this Playbook you'll need to have the needed Ansible Collections already installed - you can do so easily by running the following command:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Modify the Variables files

- Copy `example_vars/cluster-config.yaml` to the working directory, ideally with a prefix of the cluster name - modify as needed
- Modify the other files in `example_vars/` and copy to `vars/` as you see fit, in case you need to add the new cluster to an ACM Hub for instance

## Running the Playbook

With the needed variables altered, you can run the Playbook with the following command:

```bash
ansible-playbook -e "@cluster-name.cluster-config.yaml" bootstrap.yaml
```

## Available Tags

- `create_libvirt_cluster` - Create the Libvirt VMs, skipping can speed up things if retrying post-provisioning tasks
- `post_tasks_1` - Default post-cluster provisioning Tasks, adding Matrix Login, NFS StorageClass, NFS for Image Registry, & LDAP IdP
- `post_tasks_2` - Connect the new cluster to an Advanced Cluster Management Hub