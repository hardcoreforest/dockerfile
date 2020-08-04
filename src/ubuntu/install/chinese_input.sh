#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install ibus-pinyin components"
apt-get update

apt-get install -y ibus ibus-clutter ibus-gtk ibus-gtk3 ibus-qt4
im-config -s ibus
apt-get install -y ibus-pinyin

apt-get clean -y