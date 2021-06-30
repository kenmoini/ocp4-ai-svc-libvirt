#!/bin/bash

NODE_SSH_KEY="..."
request_body=$(mktemp)

jq -n --arg SSH_KEY "$NODE_SSH_KEY" --arg NMSTATE_YAML1 "$(cat .generated/2869116a-f943-4d34-8841-ffd8ba95c0c2/iso_params.json)" \
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