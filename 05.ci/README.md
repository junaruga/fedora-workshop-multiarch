# 05.ci - qemu-user-static, binfmt_misc, container and CI

Table of contents

* 1 Case: Travis CI
* 2 Case: Other CIs supporting multi-architectures

## 1. Case: Travis CI

As Travis CI is running on Ubuntu as the host OS. The host architecture is x86_64.
The latest available Ubuntu is Ubuntu version name "xenial".

Let's add Fedora multiarch containers on the CI!

See this repository's `.travis.yml` and the [Travis CI](https://travis-ci.org/junaruga/fedora-workshop-multiarch) page.

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
