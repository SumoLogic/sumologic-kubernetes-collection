#!/bin/bash

set -x

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get --yes upgrade
apt-get --yes install apt-transport-https

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

# allow privileged
echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver
systemctl restart snap.microk8s.daemon-kubelet.service
systemctl restart snap.microk8s.daemon-apiserver.service

# allow connections to outside
iptables -P FORWARD ACCEPT
apt-get install --yes iptables-persistent
# Somehow persistent iptables doesn't work - let's use this ugly hack to force iptables reload on every bash login
echo "sudo iptables -P FORWARD ACCEPT" >> /home/vagrant/.bashrc

echo "export KUBECONFIG=/var/snap/microk8s/current/credentials/kubelet.config" >> /home/vagrant/.bashrc

HELM_2_VERSION=v2.16.9
HELM_3_VERSION=v3.2.4

mkdir /opt/helm2 /opt/helm3
curl https://get.helm.sh/helm-${HELM_2_VERSION}-linux-amd64.tar.gz | tar -xz -C /opt/helm2
curl https://get.helm.sh/helm-${HELM_3_VERSION}-linux-amd64.tar.gz | tar -xz -C /opt/helm3

ln -s /opt/helm2/linux-amd64/helm /usr/bin/helm2
ln -s /opt/helm3/linux-amd64/helm /usr/bin/helm3
ln -s /usr/bin/helm3 /usr/bin/helm

usermod -a -G microk8s vagrant

# install yq with access to file structure
curl https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 -L -o /usr/local/bin/yq-3.2.1
chmod +x /usr/local/bin/yq-3.2.1
curl https://github.com/mikefarah/yq/releases/download/3.3.0/yq_linux_amd64 -L -o /usr/local/bin/yq-3.3.0
chmod +x /usr/local/bin/yq-3.3.0
ln -s /usr/local/bin/yq-3.3.0 /usr/local/bin/yq

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

# Init helm tiller
sudo -H -u vagrant -i helm2 init --wait

echo Dashboard local in-vagrant IP:
kubectl -n kube-system get services | grep -i kubernetes-dashboard | awk '{print $3}'
echo

echo Dashboard token:
kubectl -n kube-system describe secret default| awk '$1=="token:"{print $2}'
echo
