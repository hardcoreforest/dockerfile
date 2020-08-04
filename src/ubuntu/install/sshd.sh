#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install SSH components"
apt-get update

apt-get install -y openssh-server sshpass
mkdir -p /root/.ssh && chown root.root /root \
        && chmod 700 /root/.ssh \
        && touch /root/.ssh/authorized_keys \
        && chmod 600 /root/.ssh/authorized_keys \
        && mkdir -p /var/run/sshd \
        && sed  -i "/^[^#]*PermitRootLogin/ s/.*/#&/"  /etc/ssh/sshd_config && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "root:${SSH_PW}" | chpasswd
apt-get clean -y