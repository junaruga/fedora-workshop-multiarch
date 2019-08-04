# Fedora Workshop for multiarch

[![Travis Build Status](https://travis-ci.org/junaruga/fedora-workshop-multiarch.svg?branch=master)](https://travis-ci.org/junaruga/fedora-workshop-multiarch)

* Fock 2019 talk: [Talk-25]: [Let's add Fedora multiarch containers to your CI](https://pagure.io/flock/issue/182)

## Table of contents

* 1 [qemu-user-static and binfmt_misc](01.basic/README.md)
  * 1.1 qemu-user-static
  * 1.2 qemu-user-static and binfmt_misc
* 2 [qemu-user-static and binfmt_misc on Fedora](02.system/README.md)
* 3 [qemu-user-static, binfmt_misc and chroot on Fedora](03.chroot/README.md)
* 4 [qemu-user-static, binfmt_misc and container on Fedora](04.container/README.md)
* 5 [qemu-user-static, binfmt_misc, container and CI](05.ci/README.md)

## See also

* [multiarch/qemu-user-static](https://github.com/multiarch/qemu-user-static): We are using this tool to add Fedora multiarch containers to CI.
* [ci-multi-arch-test](https://github.com/junaruga/ci-multi-arch-test): See this project if you want to know some cases of other distributions such as Ubuntu and CentOS.
