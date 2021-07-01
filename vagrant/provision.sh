#!/bin/bash

set -x

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get --yes upgrade
apt-get --yes install apt-transport-https jq

echo "export EDITOR=vim" >> /home/vagrant/.bashrc

snap install microk8s --classic --channel=1.18/stable
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
sed -i '/address/d' kube-scheduler
sed -i '/address/d' kub-controller-manager

systemctl restart snap.microk8s.daemon-kubelet.service
systemctl restart snap.microk8s.daemon-apiserver.service

# allow connections to outside
iptables -P FORWARD ACCEPT
apt-get install --yes iptables-persistent
# Somehow persistent iptables doesn't work - let's use this ugly hack to force iptables reload on every bash login
echo "sudo iptables -P FORWARD ACCEPT" >> /home/vagrant/.bashrc

echo "export KUBECONFIG=/var/snap/microk8s/current/credentials/kubelet.config" >> /home/vagrant/.bashrc

HELM_3_VERSION=v3.5.4

mkdir /opt/helm3
curl "https://get.helm.sh/helm-${HELM_3_VERSION}-linux-amd64.tar.gz" | tar -xz -C /opt/helm3

ln -s /opt/helm3/linux-amd64/helm /usr/bin/helm3
ln -s /usr/bin/helm3 /usr/bin/helm

usermod -a -G microk8s vagrant

# install yq with access to file structure
curl https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -L -o /usr/local/bin/yq-3.4.1
chmod +x /usr/local/bin/yq-3.4.1
ln -s /usr/local/bin/yq-3.4.1 /usr/local/bin/yq

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker vagrant

# Install make
apt-get install -y make

# K8s needs some time to bootstrap
while true; do
  kubectl -n kube-system get services 1>/dev/null 2>&1 && break
  echo 'Waiting for k8s server'
  sleep 1
done

# install requirements for ci/build.sh
snap install ruby --channel=2.6/stable --classic
gem install bundler
apt install -y gcc g++ libsnappy-dev libicu-dev zlib1g-dev cmake pkg-config libssl-dev

SHELLCHECK_VERSION=v0.7.1
curl -Lo- "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" | tar -xJf -
sudo cp "shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin
rm -rf "shellcheck-${SHELLCHECK_VERSION}/"

gem install mdl
# shellcheck disable=SC2016
echo 'export PATH="$PATH:$HOME/.gem/bin"' >> /home/vagrant/.bashrc

apt-get install -y yamllint

K9S_VERSION=v0.24.2
mkdir /opt/k9s
curl -Lo- "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_x86_64.tar.gz" | tar -C /opt/k9s -xzf -
ln -s /opt/k9s/k9s /usr/bin/k9s

echo Dashboard local in-vagrant IP:
kubectl -n kube-system get services | grep -i kubernetes-dashboard | awk '{print $3}'
echo

echo Dashboard token:
/sumologic/vagrant/scripts/get-dashboard-token.sh
echo

ln -s /sumologic/vagrant/scripts/sumo-make.sh /usr/local/bin/sumo-make
ln -s /sumologic/vagrant/scripts/sumo-make-completion.sh /etc/bash_completion.d/sumo-make
