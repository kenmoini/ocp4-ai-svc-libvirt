# OpenShift 4 Assisted Installer on Libvirt/KVM

This set of resources handles an idempotent way to deploy OpenShift via an Assisted Installer service onto a Libvirt/KVM host.

## Operations

What this Ansible content will do is the following:

### bootstrap.yaml

1. Do preflight for binaries, create asset generation directory
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