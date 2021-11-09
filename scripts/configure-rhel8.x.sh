#!/bin/bash
set -xe 
CHECKLOGGINGUSER=$(whoami)
if [ ${CHECKLOGGINGUSER} == "root" ];
then 
  echo "login as sudo user to run script."
  echo "You are currently logged in as root"
  exit 1
fi


sudo subscription-manager register
sudo subscription-manager refresh
sudo subscription-manager attach --auto
sudo subscription-manager repos --enable=rhel-8-for-x86_64-appstream-rpms --enable=rhel-8-for-x86_64-baseos-rpms
sudo dnf install git vim unzip wget bind-utils  jq ansible  -y 
sudo dnf install ncurses-devel curl -y
sudo dnf install @virt -y
sudo dnf -y install libvirt-devel virt-top libguestfs-tools -y
sudo systemctl enable --now libvirtd
curl 'https://vim-bootstrap.com/generate.vim' --data 'editor=vim&langs=javascript&langs=go&langs=html&langs=ruby&langs=python' > ~/.vimrc

cd ~
git clone https://github.com/chris-marsh/pureline.git
cp pureline/configs/powerline_full_256col.conf ~/.pureline.conf

sudo tee -a .bashrc > /dev/null <<EOT
if [ "$TERM" != "linux" ]; then
    source ~/pureline/pureline ~/.pureline.conf
fi
EOT

 source ~/.bashrc 

 git clone https://github.com/tosin2013/ocp4-ai-svc-libvirt.git
 git clone https://github.com/kenmoini/homelab.git