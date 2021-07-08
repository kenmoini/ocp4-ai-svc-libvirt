# OpenShift 4 Assisted Installer on Libvirt/KVM

This set of resources handles an idempotent way to deploy OpenShift via an Assisted Installer service onto a Libvirt/KVM host.

## Installing Ansible Collections

In order to run this Playbook you'll need to have the needed Ansible Collections already installed - you can do so easily by running the following command:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Modify the Variables files

## Running the Playbook

With the needed variables altered, you can run the Playbook with the following command:

```bash
ansible-playbook bootstrap.yaml
```