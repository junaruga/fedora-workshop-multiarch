#!/bin/bash
set -xe

# How to install docker-ce on Ubuntu
# https://docs.docker.com/install/linux/docker-ce/ubuntu/
# Examples: DOCKER_BUILDKIT=1 docker build --t $TAG --platform $PLATFORM
# https://github.com/containers/buildah/issues/1590#issuecomment-517225516
sudo apt-get -y remove cri-o-runc
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
sudo apt-get -y update
sudo apt-get -o Dpkg::Options::="--force-overwrite" install -f docker-ce docker-ce-cli containerd.io
docker version
DOCKER_BUILDKIT=1 docker build --help
