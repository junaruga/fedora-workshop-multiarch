#!/bin/bash
set -xe

mkdir -p ~/.config/containers
cp -p ci/registries.conf ~/.config/containers/
cp -p ci/storage.conf ~/.config/containers/
USER_ID="$(id -u)"
USER_NAME="$(id -un)"
sed -i "s/@USER_ID@/${USER_ID}/" ~/.config/containers/storage.conf
sed -i "s/@USER_NAME@/${USER_NAME}/" ~/.config/containers/storage.conf

# No such file or directory
var_dirs="
    /var/lib/containers
    /var/run/containers
    /var/run/libpod
"
for var_dir in ${var_dirs}; do
    sudo ls "${var_dir}" || true
    sudo mkdir -p "${var_dir}"
    sudo chown -R "${USER_NAME}" "${var_dir}"
done
podman info --debug
