#!/bin/bash

NODE_SSH_KEY="..."
request_body=$(mktemp)

jq -n --arg SSH_KEY "$NODE_SSH_KEY" --arg NMSTATE_YAML1 "$(cat templates/host_static_networking.yaml.j2)" \
'{
  "ssh_public_key": $SSH_KEY,
  "image_type": "full-iso",
  "static_network_config": [
    {
      "network_yaml": $NMSTATE_YAML1,
      "mac_interface_map": [{"mac_address": "02:00:00:2c:23:a5", "logical_nic_name": "eth0"}, {"mac_address": "02:00:00:68:73:dc", "logical_nic_name": "eth1"}]
    }
  ]
}' >> $request_body

cat $request_body