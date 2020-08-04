#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

echo "Install Common components"
apt-get update

apt-get install -y apt-utils

apt-get clean -y