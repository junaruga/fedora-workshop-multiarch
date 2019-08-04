# 05.ci - qemu-user-static, binfmt_misc, container and CI

Table of contents

* 1 Case: Travis CI
* 2 Case: Other CIs supporting multi-architectures

## 1. Case: Travis CI

As Travis CI is running on Ubuntu as the host OS. The host architecture is x86_64.
The latest available Ubuntu is Ubuntu version name "xenial".

Let's add Fedora multiarch containers on the CI with "multiarch/qemu-user-static" now [1]!

See this repository's [.travis.yml](https://github.com/junaruga/fedora-workshop-multiarch/blob/master/.travis.yml) and the [Travis CI](https://travis-ci.org/junaruga/fedora-workshop-multiarch) page.
"multiarch/qemu-user-static" is a container image to set host OS's binfmt_misc files with `qemu-$cpu-static` binary files from inside of the container, when it is executed. As we discussed, binfmt_misc files are commonly used between inside container and host OS, as a result, host OS's binfmt_misc files are added or updated.

We are using what you learned until this section.

## 2 Case: Other CIs supporting multi-architectures

Travis CI only supports x86_64 as the host OS environment.
But some CI supports other archititecture such as aarch64 (ARM 64-bit) or ARM 32-bit.

* Shippable CI [2]
* Drone CI [3]
* Works on ARM [4]

## 3 References

* [1] multiarch/qemu-user-static: https://github.com/multiarch/qemu-user-static
* [2] Shippable CI: https://www.shippable.com/
  http://docs.shippable.com/platform/tutorial/workflow/run-ci-builds-on-arm/
* [3] Drone CI: https://drone.io/
  https://blog.drone.io/drone-announces-official-support-for-arm/
* [4] Works on ARM: https://www.worksonarm.com/cluster/
