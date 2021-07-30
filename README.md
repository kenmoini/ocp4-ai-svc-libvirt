# OpenShift 4 Assisted Installer Service, Libvirt Deployer

There are two options to use this source:

1. Ideally, go with the resources in the `ansible` folder, it's more complete and intelligent/idempotent
2. Do it the hard way with the Bash scripts in the `old_bash_scripts` folder which are not as complete but do a decent job

## Background Information & Sources

- assisted-service Source: https://github.com/openshift/assisted-service
- assisted-service OnPrem Deployment: https://github.com/sonofspike/assisted-service-onprem
- Podman & Systemd AI Svc Deployment: https://github.com/kenmoini/homelab/blob/main/ansible-collections/deploy-caas-ocp-assisted-installer.yml