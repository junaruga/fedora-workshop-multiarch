#!/bin/bash
set -xe

dpkg-query -L containers-common
dpkg-query -L podman

# USER_ID="$(id -u)"
USER_NAME="$(id -un)"
CWD="$(pwd)"

# registries.conf
dpkg -S /etc/containers/registries.conf
cat /etc/containers/registries.conf
sudo cp -p ci/registries.conf /etc/containers/registries.conf
# mkdir -p ~/.config/containers
# cp -p ci/registries.conf ~/.config/containers/

# storage.conf
dpkg -S /etc/containers/storage.conf
cat /etc/containers/storage.conf

sed -i "s|@CWD@|${CWD}|" ci/root_storage.conf.in
sudo cp -p ci/root_storage.conf.in /etc/containers/storage.conf

# cp -p ci/storage.conf ~/.config/containers/
# sed -i "s/@USER_ID@/${USER_ID}/" ~/.config/containers/storage.conf
# sed -i "s/@USER_NAME@/${USER_NAME}/" ~/.config/containers/storage.conf

# No such file or directory
var_dirs="
    /var/lib/containers
    /var/run/containers
    /var/run/libpod
    /var/lib/containers/storage
    /var/lib/containers/storage/overlay
    ${CWD}/root/var/run/containers/storage
    ${CWD}/root/var/lib/containers/storage
"
for var_dir in ${var_dirs}; do
    sudo ls "${var_dir}" || true
    sudo mkdir -p "${var_dir}"
    sudo chown -R "${USER_NAME}" "${var_dir}"
done
podman info --debug
sudo podman info --debug
