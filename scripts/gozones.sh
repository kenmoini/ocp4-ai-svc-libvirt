#!/bin/bash
## https://computingforgeeks.com/how-to-disable-ipv6-on-linux/


## Set vars
if [ -f $HOME/dns.env ];
then 
    source  $HOME/dns.env
else
    read -p "Enter Path for files Example: /opt/disconnected-mirror  > " MIRROR_BASE_PATH
    read -p "Enter VM Hostname Example: dns> " MIRROR_VM_HOSTNAME
    read -p "Enter target Interface: ens192 > " TARGET_INTERFACE
    echo "Collecting IP for  $TARGET_INTERFACE"
    export CURRENT_IP=$(echo `ifconfig $TARGET_INTERFACE |awk '/inet/ {print $2}'| grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b"`)
    export IP_OCTET=$(echo ${CURRENT_IP} | cut -d"." -f1-3)
    read -p "Enter Bridge Interface ip Example: ${CURRENT_IP} > " MIRROR_VM_ISOLATED_BRIDGE_IFACE_IP
    read -p "Enter Domain Network Example: example.com > " ISOLATED_NETWORK_DOMAIN
    read -p "Enter Network CIDR Range Example: ${IP_OCTET}.0/24 > " ISOLATED_NETWORK_CIDR
    read -p "Enter Forward IP to foward dns lookups > " FORWARD_IP
    read -p "Enter Cluster name for OpenShift Cluster Example: ocp4 > " CLUSTER_NAME
fi

cat <<EOF > $HOME/dns.env
export MIRROR_BASE_PATH=${MIRROR_BASE_PATH}
export MIRROR_VM_HOSTNAME=${MIRROR_VM_HOSTNAME}
export MIRROR_VM_ISOLATED_BRIDGE_IFACE_IP=${MIRROR_VM_ISOLATED_BRIDGE_IFACE_IP}
export ISOLATED_NETWORK_DOMAIN=${ISOLATED_NETWORK_DOMAIN}
export ISOLATED_NETWORK_CIDR=${ISOLATED_NETWORK_CIDR}
export FORWARD_IP=${FORWARD_IP}
export CLUSTER_NAME=${CLUSTER_NAME}
export IP_OCTET=${IP_OCTET}
EOF


sudo dnf module install -y container-tools
sudo yum install slirp4netns podman  bind-utils -y
sudo tee -a /etc/sysctl.d/userns.conf > /dev/null <<EOT
user.max_user_namespaces=28633
EOT
sudo sysctl -p /etc/sysctl.d/userns.conf

cat  >/etc/sysctl.d/ipv6.conf<<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
sysctl -p /etc/sysctl.d/ipv6.conf

# Create the YAML File
mkdir -p ${MIRROR_BASE_PATH}/dns/volumes/go-zones/
mkdir -p ${MIRROR_BASE_PATH}/dns/volumes/bind/
curl -L https://raw.githubusercontent.com/kenmoini/go-zones/main/container_root/opt/app-root/vendor/bind/named.conf  --output $MIRROR_BASE_PATH/dns/volumes/bind/named.conf
ls -alth  $MIRROR_BASE_PATH/dns/volumes/bind/named.conf || exit $?
cat > $MIRROR_BASE_PATH/dns/volumes/go-zones/zones.yml <<EOF
zones:
  - name: $ISOLATED_NETWORK_DOMAIN
    subnet: $ISOLATED_NETWORK_CIDR
    network: internal
    primary_dns_server: $MIRROR_VM_HOSTNAME.$ISOLATED_NETWORK_DOMAIN
    ttl: 3600
    records:
      NS:
        - name: $MIRROR_VM_HOSTNAME
          ttl: 86400
          domain: $ISOLATED_NETWORK_DOMAIN.
          anchor: '@'
      A:
        - name: $MIRROR_VM_HOSTNAME
          ttl: 6400
          value: $MIRROR_VM_ISOLATED_BRIDGE_IFACE_IP
        - name: api.${CLUSTER_NAME}
          ttl: 6400
          value: ${IP_OCTET}.10
        - name: api-int.${CLUSTER_NAME}
          ttl: 6400
          value: ${IP_OCTET}.10
        - name: '*.apps.${CLUSTER_NAME}'
          ttl: 6400
          value: ${IP_OCTET}.11
EOF

## Create a forwarder file to redirect all other inqueries to this Mirror VM
mkdir -p ${MIRROR_BASE_PATH}/dns/volumes/bind/
cat > $MIRROR_BASE_PATH/dns/volumes/bind/external_forwarders.conf <<EOF
forwarders {
  127.0.0.53;
  ${FORWARD_IP};
};
EOF

podman run -d --name dns-go-zones \
 --net host \
 -m 512m \
 -v $MIRROR_BASE_PATH/dns/volumes/go-zones:/etc/go-zones/:Z \
 -v $MIRROR_BASE_PATH/dns/volumes/bind:/opt/app-root/vendor/bind/:Z \
 quay.io/kenmoini/go-zones:file-to-bind


podman generate systemd \
    --new --name dns-go-zones \
    > /etc/systemd/system/dns-go-zones.service

systemctl enable dns-go-zones
systemctl start dns-go-zones
systemctl status dns-go-zones
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --reload


dig  @127.0.0.1 test.apps.${CLUSTER_NAME}.${ISOLATED_NETWORK_DOMAIN}
dig  @${MIRROR_VM_ISOLATED_BRIDGE_IFACE_IP} test.apps.${CLUSTER_NAME}.${ISOLATED_NETWORK_DOMAIN}

echo "API IP: ${IP_OCTET}.10"
echo "Ingress IP: ${IP_OCTET}.11"