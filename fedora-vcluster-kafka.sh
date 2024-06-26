###!/bin/bash
#
# Uncomment to see where the variables may fail
# ---------------------------------------------
#set -x
#
# Add your variables below
# ------------------------
# ON your management machine and with all nodes active
# and your docker configuration enabled for remote access
# Please be sure to setup your CA (consider mkcert --install)
#
# Globals
# -------
export USER=jsoehner
export CAROOT=ssl/
export CLIENT_CERT=Jeffs-MacBook+1-client
export HUB_IP=192.168.100.70
export NODE_HOSTNAME=cluster2
export DOMAIN_NAME=jsigroup.local
#
# Assuming you have already installed your CA into a sub directory called
# 'ssl' this part creates a daemon cert and adds the rootCA, docker daemon
# cert and key onto the docker host
#
mkcert ${NODE_HOSTNAME}.${DOMAIN_NAME} ${HUB_IP} >/dev/null 2>&1
mv ${NODE_HOSTNAME}.${DOMAIN_NAME}*.pem ssl/ >/dev/null 2>&1
scp ssl/rootCA.pem ${USER}@${NODE_HOSTNAME}:~ >/dev/null 2>&1
scp ssl/${NODE_HOSTNAME}.${DOMAIN_NAME}+?.pem ${USER}@${NODE_HOSTNAME}:~ >/dev/null 2>&1
scp ssl/${NODE_HOSTNAME}.${DOMAIN_NAME}+?-key.pem ${USER}@${NODE_HOSTNAME}:~ >/dev/null 2>&1
#
# Create a new docker context and switch to the new context
# ---------------------------------------------------------
#
docker context rm ${NODE_HOSTNAME} -f >/dev/null 2>&1
docker context create ${NODE_HOSTNAME}\
  --description "${NODE_HOSTNAME} context created"\
  --docker "host=tcp://${HUB_IP}:2376,ca=ssl/rootCA.pem,cert=ssl/${CLIENT_CERT}.pem,key=ssl/${CLIENT_CERT}-key.pem" >/dev/null 2>&1
docker context use ${NODE_HOSTNAME} >/dev/null 2>&1
#
# Create OpenSSL config
# ---------------------
#
tee ssl/${NODE_HOSTNAME}-openssl.cnf <<EOF >/dev/null 2>&1
    [req]
    req_extensions = v3_req
    distinguished_name = req_distinguished_name
    [req_distinguished_name]
    
    [ v3_req ]   
    basicConstraints = CA:FALSE
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = ${NODE_HOSTNAME}
    DNS.2 = ${NODE_HOSTNAME}.${DOMAIN_NAME}
    IP.1 = 127.0.0.1
    IP.2 = ${HUB_IP}
EOF
#
# Move files into position on node
# --------------------------------
#
scp ssl/${NODE_HOSTNAME}-openssl.cnf ${USER}@${NODE_HOSTNAME}:openssl.cnf >/dev/null 2>&1
ssh -t ${USER}@${NODE_HOSTNAME} 'sudo mkdir -p /etc/docker/ssl' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/openssl.cnf /etc/docker/ssl/openssl.cnf' >/dev/null 2>&1
#
# Remove and re-install new Trusted Root CA
#
ssh ${USER}@${NODE_HOSTNAME} 'sudo rm -f /etc/pki/ca-trust/source/anchors/docker-root-ca.crt' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo cp -f ~/rootCA.pem  /etc/pki/ca-trust/source/anchors/docker-root-ca.crt' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo update-ca-trust' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/rootCA.pem /etc/docker/ssl/rootCA.pem' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/*.jsigroup.local+1.pem /etc/docker/ssl/daemon-cert.pem' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/*.jsigroup.local+1-key.pem /etc/docker/ssl/daemon-key.pem' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo chmod 600 /etc/docker/ssl/*' >/dev/null 2>&1
scp ssl/daemon.json ${USER}@${NODE_HOSTNAME}:~ >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/daemon.json /etc/docker/daemon.json' >/dev/null 2>&1
#
# Patch systemd for flag error
# ----------------------------
ssh ${USER}@${NODE_HOSTNAME} 'sudo cp /lib/systemd/system/docker.service /etc/systemd/system/' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo sed -i "s/\-H fd:\/\///" /etc/systemd/system/docker.service' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo systemctl daemon-reload' >/dev/null 2>&1
ssh ${USER}@${NODE_HOSTNAME} 'sudo service docker restart' >/dev/null 2>&1
#
# Remove any stale clusters
# -------------------------
kind delete cluster --name $(kind get clusters 2>/dev/null)
#
# Create a remote kind cluster on remote host
# -------------------------------------------
#
cat <<EOF | kind create cluster  --name ${NODE_HOSTNAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: ${HUB_IP}
  apiServerPort: 6443
  podSubnet: "10.240.0.0/16"
  serviceSubnet: "172.16.0.0/12"
  disableDefaultCNI: true
  kubeProxyMode: none
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
printf "  *** Please wait while we install Cilium... ***\n"
helm repo update >/dev/null 2>&1
cilium install --version 1.16.0-pre.2 \
  --set kubeProxyReplacement=true \
  --set ingressController.enabled=true \
  --set ingressController.loadbalancerMode=dedicated \
  --set ingressController.default=true
sleep 30
# Creates a kafka cluster 3 controllers / 3 Brokers using TLS
vcluster create strimzi-1 -f vcluster.yaml --connect=false
printf "  *** Lets pause while the vcluster becomes active... ***\n"
vcluster connect strimzi-1 -- kubectl create namespace kafka
printf "  *** Lets add the kafka software... ***\n"
vcluster connect strimzi-1 -- kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka
vcluster connect strimzi-1 -- kubectl create -f 'https://strimzi.io/examples/latest/kafka/kraft/kafka-ephemeral.yaml' -n kafka
printf "  *** Lets pause while the kafka cluster becomes active... ***\n"
vcluster connect strimzi-1 -- kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n kafka
printf "  *** Lets initialize an example of a producer and a consume... ***\n"
vcluster connect strimzi-1 -- kubectl create -f 'https://raw.githubusercontent.com/strimzi/client-examples/main/java/kafka/deployment-ssl.yaml' -n kafka
printf "  *** All Done - Enjoy... ***\n"
