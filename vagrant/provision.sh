#!/bin/bash

set -euo pipefail

LSB_RELEASE="$(lsb_release -cs)"
ARCH="$(dpkg --print-architecture)"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get --yes upgrade
apt-get --yes install apt-transport-https make ca-certificates curl gnupg

echo "export EDITOR=vim" >> /home/vagrant/.bashrc

snap install microk8s --classic --channel=1.23/stable
microk8s.status --wait-ready
ufw allow in on cbr0
ufw allow out on cbr0
ufw default allow routed

microk8s enable dashboard
microk8s enable registry
microk8s enable storage
microk8s enable dns

microk8s.kubectl config view --raw > /sumologic/.kube-config

snap alias microk8s.kubectl kubectl

# allow webhook authentication
echo "--authentication-token-webhook=true" >> /var/snap/microk8s/current/args/kubelet
echo "--authorization-mode=Webhook" >> /var/snap/microk8s/current/args/kubelet
# allow privileged
echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver
# remove address flags to listen on all interfaces
sed -i '/address/d' /var/snap/microk8s/current/args/kube-scheduler
sed -i '/address/d' /var/snap/microk8s/current/args/kube-controller-manager

systemctl restart snap.microk8s.daemon-kubelet.service
systemctl restart snap.microk8s.daemon-apiserver.service

# allow connections to outside
iptables -P FORWARD ACCEPT
apt-get install --yes iptables-persistent
# Somehow persistent iptables doesn't work - let's use this ugly hack to force iptables reload on every bash login
echo "sudo iptables -P FORWARD ACCEPT" >> /home/vagrant/.bashrc

echo "export KUBECONFIG=/var/snap/microk8s/current/credentials/kubelet.config" >> /home/vagrant/.bashrc

usermod -a -G microk8s vagrant

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu \
   ${LSB_RELEASE} \
   stable"
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker vagrant

# Install nix
curl -L https://nixos.org/nix/install -o /tmp/install-nix.sh
command -v nix-shell || sh /tmp/install-nix.sh --daemon --yes
# shellcheck source=/dev/null
source "/etc/bashrc"

# install k9s and direnv
nix-env -i k9s direnv

# set up direnv and the nix shell environment
echo "eval \"\$(direnv hook bash)\"" >> /home/vagrant/.bashrc
echo "use nix /sumologic/shell.nix" > /home/vagrant/.envrc

echo "Building Nix shell environment"
sudo -u vagrant bash -c "source /etc/bashrc; direnv allow /home/vagrant; cd /home/vagrant; nix-shell /sumologic/shell.nix"

# K8s needs some time to bootstrap
while true; do
  kubectl -n kube-system get services 1>/dev/null 2>&1 && break
  echo 'Waiting for k8s server'
  sleep 1
done

ln -sf /sumologic/vagrant/scripts/sumo-make.sh /usr/local/bin/sumo-make
ln -sf /sumologic/vagrant/scripts/sumo-make-completion.sh /etc/bash_completion.d/sumo-make

# print out summary
echo Dashboard local in-vagrant IP:
kubectl -n kube-system get services | grep -i kubernetes-dashboard | awk '{print $3}'
echo

echo Dashboard token:
/sumologic/vagrant/scripts/get-dashboard-token.sh

