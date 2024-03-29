#!/bin/bash
set -xe

# Building docker buildx.
# https://github.com/docker/buildx#building
pushd ~
git clone https://github.com/docker/buildx.git
cd buildx
make install
popd
docker buildx version
docker buildx inspect
