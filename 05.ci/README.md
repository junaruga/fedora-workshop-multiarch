# 05.ci - qemu-user-static, binfmt_misc, container and CI

Table of contents

* 1 Case: Travis CI
  1.1 Understanding qemu-user-static and binfmt_misc on Ubuntu
  1.2 Let's add Fedora multiarch containers on the CI!
* 2 Case: Other CIs supporting multi-architectures

## 1. Case: Travis CI

### 1.1 qemu-user-static and binfmt_misc on Ubuntu

As Travis CI is running on Ubuntu as the host OS. The host architecture is x86_64.
The latest available Ubuntu is Ubuntu version name "xenial".
We describe about qemu-user-static and binfmt_misc on Ubuntu xenial on this section.

But you can set to install the Ubuntu newer version bionic's newer deb package like this in `.travis.yml`.

```
dist: xenial
services:
  - docker
language: bash
addons:
  apt:
    config:
      retries: true
    update: true
      sources:
        - sourceline: 'deb http://archive.ubuntu.com/ubuntu bionic main universe'
      packages:
        # Install wget >= 1.19.1 to use wget --retry-on-http-error=NNN,NNN option
        # https://lists.gnu.org/archive/html/bug-wget/2017-02/msg00065.html
        # https://packages.ubuntu.com/bionic/wget
        - wget
```

```
$ podman pull ubuntu:xenial
$ podman run --rm -it ubuntu:xenial bash
root@03d42709994a:/#

root@03d42709994a:/# apt-get install qemu binfmt-support qemu-user-static
```

Working in progress:
See https://github.com/systemd/systemd/issues/13129#issuecomment-513893380


### 1.2 Let's add Fedora multiarch containers on the CI!

Working in progress.

## 2 Case: Other CIs supporting multi-architectures

Travis CI only supports x86_64 as the host OS environment.
But some CI supports other archititecture such as aarch64 (ARM 64-bit) or ARM 32-bit.

* Shippable CI [1]
* Drone CI [2]
* Works on ARM [3]

## 3 References

* [1] Shippable CI: https://www.shippable.com/
  http://docs.shippable.com/platform/tutorial/workflow/run-ci-builds-on-arm/
* [2] Drone CI: https://drone.io/
  https://blog.drone.io/drone-announces-official-support-for-arm/
* [3] Works on ARM: https://www.worksonarm.com/cluster/
