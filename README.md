# OpenShift 4 Assisted Installer Service, Libvirt Deployer

> ATTENTION: Navigate to the `ansible` directory for up-to-date automation - other assets are used for bootstrapping control nodes or kept for legacy purposes

There are two options to use this source:

1. Ideally, go with the resources in the `ansible` folder, it's more complete and intelligent/idempotent
2. Do it the hard way with the Bash scripts in the `old_bash_scripts` folder which are not as complete but do a decent job

## Background Information & Sources

- assisted-service Source: https://github.com/openshift/assisted-service
- assisted-service OnPrem Deployment: https://github.com/sonofspike/assisted-service-onprem
- Podman & Systemd AI Svc Deployment: https://github.com/kenmoini/homelab/blob/main/ansible-collections/deploy-caas-ocp-assisted-installer.yml
- Red Hat Console hosted Assisted Installer Service: https://console.redhat.com/openshift/assisted-installer/clusters

### Extra Information

- Last tested on 8/10/2021 with:
  - quay.io/ocpmetal/ocp-metal-ui:stable-candidate.10.08.2021-08.28
  - quay.io/ocpmetal/assisted-service:stable-candidate.10.08.2021-08.28
  - quay.io/ocpmetal/postgresql-12-centos7
  - quay.io/coreos/coreos-installer:v0.10.0
- Usable with self-hosted Assisted Installer Service or Red Hat Cloud/Console hosted AI Service