####!/bin/bash
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
export NODE_VERSION=v1.27.0
export USER=jsoehner
export CAROOT=ssl/
export CLIENT_CERT=Jeffs-MacBook+1-client
export HUB_IP=192.168.100.200
export HUB_NAME=velad1
export DOMAIN_NAME=jsigroup.local
#
# TODO: Need to modify script for domain name
#
# ------------------------------
# Create a connection to the hub
# ------------------------------
#
export NODE_HOSTNAME=velad1
#
# Assuming you have already installed your CA into a sub directory called
# 'ssl' this part creates a daemon cert and adds the rootCA, docker daemon
# cert and key onto the docker host
#
mkcert ${NODE_HOSTNAME}.${DOMAIN_NAME} ${HUB_IP}
mv ${NODE_HOSTNAME}.${DOMAIN_NAME}*.pem ssl/
scp ssl/rootCA.pem ${USER}@${NODE_HOSTNAME}:~
scp ssl/${NODE_HOSTNAME}.${DOMAIN_NAME}+?.pem ${USER}@${NODE_HOSTNAME}:~
scp ssl/${NODE_HOSTNAME}.${DOMAIN_NAME}+?-key.pem ${USER}@${NODE_HOSTNAME}:~
#rm -rf ssl/${NODE_HOSTNAME}.${DOMAIN_NAME}+?*
#
# Create a new docker context and switch to the new context
# ---------------------------------------------------------
#
docker context rm ${NODE_HOSTNAME} -f
docker context create ${NODE_HOSTNAME}\
  --description "${NODE_HOSTNAME} context created"\
  --docker "host=tcp://${HUB_IP}:2376,ca=ssl/rootCA.pem,cert=ssl/${CLIENT_CERT}.pem,key=ssl/${CLIENT_CERT}-key.pem"
docker context use ${NODE_HOSTNAME}
#
# Create OpenSSL config
# ---------------------
#
tee ssl/${NODE_HOSTNAME}-openssl.cnf <<EOF
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
scp ssl/${NODE_HOSTNAME}-openssl.cnf ${USER}@${NODE_HOSTNAME}:openssl.cnf
ssh -t ${USER}@${NODE_HOSTNAME} 'sudo mkdir -p /etc/docker/ssl'
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/openssl.cnf /etc/docker/ssl/openssl.cnf'
#
# Remove and re-install new Trusted Root CA
#
ssh ${USER}@${NODE_HOSTNAME} 'sudo rm -f /etc/pki/ca-trust/source/anchors/docker-root-ca.crt'
ssh ${USER}@${NODE_HOSTNAME} 'sudo cp -f ~/rootCA.pem  /etc/pki/ca-trust/source/anchors/docker-root-ca.crt'
ssh ${USER}@${NODE_HOSTNAME} 'sudo update-ca-trust'
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/rootCA.pem /etc/docker/ssl/rootCA.pem'
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/*.jsigroup.local+1.pem /etc/docker/ssl/daemon-cert.pem'
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/*.jsigroup.local+1-key.pem /etc/docker/ssl/daemon-key.pem'
ssh ${USER}@${NODE_HOSTNAME} 'sudo chmod 600 /etc/docker/ssl/*'
scp ssl/daemon.json ${USER}@${NODE_HOSTNAME}:~
ssh ${USER}@${NODE_HOSTNAME} 'sudo mv ~/daemon.json /etc/docker/daemon.json'
#
# Patch systemd for flag error
# ----------------------------
ssh ${USER}@${NODE_HOSTNAME} 'sudo cp /lib/systemd/system/docker.service /etc/systemd/system/'
ssh ${USER}@${NODE_HOSTNAME} 'sudo sed -i "s/\-H fd:\/\///" /etc/systemd/system/docker.service'
ssh ${USER}@${NODE_HOSTNAME} 'sudo systemctl daemon-reload'
ssh ${USER}@${NODE_HOSTNAME} 'sudo service docker restart'
#
# Remove any stale clusters
# -------------------------
kind delete cluster --name $(kind get clusters 2>/dev/null) 2>/dev/null
#
# Setup Kubevela
# --------------
#ssh ${USER}@${NODE_HOSTNAME} 'sudo curl -fsSl https://static.kubevela.net/script/install-velad.sh | bash'
#ssh ${USER}@${NODE_HOSTNAME} 'sudo velad install --bind-ip=${HUB_IP}'
#ssh ${USER}@${NODE_HOSTNAME} 'sudo cat /etc/rancher/k3s/k3s.yaml' > ./velad1-kubeconfig.yaml
