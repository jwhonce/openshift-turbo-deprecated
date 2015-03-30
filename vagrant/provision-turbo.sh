#!/bin/bash

set -ex
source $(dirname $0)/provision-config.sh

# Install the required packages
yum install -y docker-io git e2fsprogs hg net-tools bridge-utils

if [ -f /etc/sysconfig/docker.rpmnew ]; then
  mv /etc/sysconfig/docker /etc/sysconfig/docker.rpmold
  mv /etc/sysconfig/docker.rpmnew /etc/sysconfig/docker
fi

echo 'Downloading OpenShift'
tar_file=/tmp/origin-v0.4.1.tgz
curl -Lk https://github.com/openshift/origin/releases/download/v0.4.1/openshift-origin-v0.4.1-2-g7a905ab-7a905ab-linux-amd64.tar.gz -o $tar_file
tar zxf $tar_file -C /tmp
mv /tmp/openshift /usr/bin
mv /tmp/osc /usr/bin

echo 'Start docker'
systemctl enable docker.service
systemctl start docker.service

# Create systemd service
cat <<EOF > /etc/systemd/system/openshift.service
[Unit]
Description=OpenShift All-In-One
Requires=docker.service network.service
After=network.service

[Service]
Type=simple
EnvironmentFile=-/etc/profile.d/openshift.sh
ExecStart=/usr/bin/openshift start --listen=http://0.0.0.0:8080
WorkingDirectory=/vagrant/

[Install]
WantedBy=multi-user.target
EOF

# Start the service
systemctl daemon-reload
systemctl enable openshift.service
systemctl start openshift.service

# Set up the KUBECONFIG environment variable for use by the client
echo 'export KUBECONFIG=/vagrant/openshift.local.certificates/admin/.kubeconfig' >> /root/.bash_profile
echo 'export KUBECONFIG=/vagrant/openshift.local.certificates/admin/.kubeconfig' >> /home/vagrant/.bash_profile
