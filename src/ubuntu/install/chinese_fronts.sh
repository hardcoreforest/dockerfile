#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install SSH components"
apt-get update

apt-get install -y language-pack-zh-hant language-pack-zh-hans ttf-wqy-zenhei xfonts-wqy
echo 'LANG="zh_CN.UTF-8"' >> /etc/environment
echo 'LANGUAGE="zh_CN:zh:en_US:en"' >> /etc/environment
dpkg-reconfigure locales
localedef -c -f UTF-8 -i zh_CN zh_CN.utf8

apt-get clean -y