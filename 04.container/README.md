# 04.container - qemu-user-static, binfmt_misc and container on Fedora

Table of contents

* 1 basic
* 2 multiarch/qemu-user-static
* 3 podman/docker buildx

---

## 1 basic

### 1.1 Introduction

`qemu-user-static` works in container environment.
Let's see how it works.

### 1.2 Experiment

#### 1.2.1 Preparation

Install `podman` or `docker`.

```
$ uname -m
x86_64

$ sudo dnf install podman

$ rpm -q podman
podman-1.4.4-4.fc30.x86_64
```

#### 1.2.2 Execution

##### Case: `/proc/sys/fs/binfmt_misc/qemu-$cpu` file with `flags: F`

Install `qemu-user-static` RPM. The flags value is `flags: F`.

```
$ sudo dnf install qemu-user-static

$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

Run arm64v8 (aarch64) container. It works.

```
$ uname -m
x86_64

$ podman pull arm64v8/fedora
$ podman run --rm -t arm64v8/fedora uname -m
aarch64
```

##### Case: No `/proc/sys/fs/binfmt_misc/qemu-$cpu` file

Then remove `/proc/sys/fs/binfmt_misc/qemu-aarch64` for next use case.

```
# echo -1 > /proc/sys/fs/binfmt_misc/qemu-aarch64

# ls /proc/sys/fs/binfmt_misc/qemu-aarch64
ls: cannot access '/proc/sys/fs/binfmt_misc/qemu-aarch64': No such file or directory
```

Run arm64v8 (aarch64) container. It does not work correctly.

```
$ podman run --rm -t arm64v8/fedora uname -m
standard_init_linux.go:211: exec user process caused "exec format error"
```

##### Case: `/proc/sys/fs/binfmt_misc/qemu-$cpu` file with `flags: `

Add `/proc/sys/fs/binfmt_misc/qemu-aarch64` file with empty flag (`flags: `).

```
# echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:" > /proc/sys/fs/binfmt_misc/register

# cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: 
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

Run arm64v8 (aarch64) container. It does not work correctly.
Because on `flags: ` (empty flag), the interpreter `/usr/bin/qemu-aarch64-static` needs to be exist in the container at run time to run QEMU.
So, you can set the interpreter to the container by `podman -v` volume mounted file.
Then it works.

```
$ podman run --rm -t arm64v8/fedora uname -m
standard_init_linux.go:211: exec user process caused "exec format error"

$ podman run --rm -t -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static arm64v8/fedora uname -m
aarch64
```

#### 1.2.3 Restoring

```
$ sudo systemctl restart systemd-binfmt
```

### 1.3 Conclusion

* `qemu-user-static` works with `podman` in container environment.
* `/proc/sys/fs/binfmt_misc` files (`register`, `status` and `qemu-$arch` files) are shared and commonly used between host and inside of container. As a result, the relation between an interpreter `/usr/bin/qemu-$cpu-static` and `/proc/sys/fs/binfmt_misc/qemu-$cpu` file that we learned at "01.basic" happens in the container as well. binfmt_misc is a feature of kernel. A container uses the host OS's kernel.

---

## 2 Dealing with container that URL does not provide architecture specific image URL.

### 2.1 Introduction

On DockerHub fedora page [1], we can see the architectures container image URL from below part of the page.

```
Supported architectures: (more info)
amd64, arm32v7, arm64v8, ppc64le, s390x
```

So, we can go to the DockerHub arm64v8/fedora page. [2]

When the container images are managed not on DockerHub, they only provide the one common image URL, how to get specific architcture image URL?
Let's learn it on this section.

### 2.2 Experiment

#### 2.2.1 Preparation

Install `skopeo` to inspect a container repository.

```
$ uname -m
x86_64

$ sudo dnf install skopeo jq

$ rpm -q skopeo jq
skopeo-0.1.37-0.gite079f9d.fc30.x86_64
jq-1.6-2.fc30.x86_64
```

#### 2.2.2 Execution

Fedora project's official container repository (registory) is [4].
The site has a tag for an architecture specific image fortunately.

By the way,`registry.fedoraproject.org` server to download a image is very slow

```
$ podman pull registry.fedoraproject.org/fedora:30-aarch64

$ podman run --rm -t registry.fedoraproject.org/fedora:30-aarch64 uname -m
aarch64
```

But even when the site does not provide the architecture specific URL, you can get the image like this with `skopeo`.

```
$ skopeo inspect --raw docker://registry.fedoraproject.org/fedora:30 | jq
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
  "manifests": [
...
    {
      "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
      "size": 429,
      "digest": "sha256:ea4b28a13ee2987f45f5da1c11500770756d2b8f01216b18190a78fdcf930410",
      "platform": {
        "architecture": "arm64",
        "os": "linux"
      }
    },
...
  ]
}

$ podman pull docker://registry.fedoraproject.org/fedora@sha256:ea4b28a13ee2987f45f5da1c11500770756d2b8f01216b18190a78fdcf930410

$ podman run --rm -t docker://registry.fedoraproject.org/fedora@sha256:ea4b28a13ee2987f45f5da1c11500770756d2b8f01216b18190a78fdcf930410 uname -m
aarch64
```

See [6] for detail. You can see how to get an image from the architecture specific URL for RHEL where the side does not provide architecture specific image URL.

#### 2.2.3 Restoring

None

---

## 3 multiarch/qemu-user-static

### 3.1 Introduction

multiarch/qemu-user-static [7] to privide consistent experience not depending on host OS to to enable an execution of different multi-architecture containers by QEMU and binfmt_misc.

When Fedora is the host OS, we can use `qemu-user-static` RPM, but when we use other OS, the experience might be different. This tool is useful to use qemu-user-static with a consistent experience on any host OS.

If you want to know Ubuntu's situation for qemu-user-static and binfmt_misc, see "05.ci" Ubuntu secition for detail.

### 3.2 Experiment

#### 3.2.1 Preparation

```
# find /proc/sys/fs/binfmt_misc -type f -name 'qemu-*' -exec sh -c 'echo -1 > {}' \;

# echo -1 > /proc/sys/fs/binfmt_misc/qemu-aarch64
```

```
$ ls /proc/sys/fs/binfmt_misc/qemu-aarch64
ls: cannot access '/proc/sys/fs/binfmt_misc/qemu-aarch64': No such file or directory

$ podman run --rm -t arm64v8/fedora uname -m
standard_init_linux.go:211: exec user process caused "exec format error"
```

#### 3.2.2 Execution

```
$ uname -m
x86_64

$ sudo podman run --rm --privileged multiarch/qemu-user-static --reset -p yes
Setting /usr/bin/qemu-alpha-static as binfmt interpreter for alpha
Setting /usr/bin/qemu-arm-static as binfmt interpreter for arm
Setting /usr/bin/qemu-armeb-static as binfmt interpreter for armeb
Setting /usr/bin/qemu-sparc32plus-static as binfmt interpreter for sparc32plus
Setting /usr/bin/qemu-ppc-static as binfmt interpreter for ppc
Setting /usr/bin/qemu-ppc64-static as binfmt interpreter for ppc64
Setting /usr/bin/qemu-ppc64le-static as binfmt interpreter for ppc64le
Setting /usr/bin/qemu-m68k-static as binfmt interpreter for m68k
Setting /usr/bin/qemu-mips-static as binfmt interpreter for mips
Setting /usr/bin/qemu-mipsel-static as binfmt interpreter for mipsel
Setting /usr/bin/qemu-mipsn32-static as binfmt interpreter for mipsn32
Setting /usr/bin/qemu-mipsn32el-static as binfmt interpreter for mipsn32el
Setting /usr/bin/qemu-mips64-static as binfmt interpreter for mips64
Setting /usr/bin/qemu-mips64el-static as binfmt interpreter for mips64el
Setting /usr/bin/qemu-sh4-static as binfmt interpreter for sh4
Setting /usr/bin/qemu-sh4eb-static as binfmt interpreter for sh4eb
Setting /usr/bin/qemu-s390x-static as binfmt interpreter for s390x
Setting /usr/bin/qemu-aarch64-static as binfmt interpreter for aarch64
Setting /usr/bin/qemu-aarch64_be-static as binfmt interpreter for aarch64_be
Setting /usr/bin/qemu-hppa-static as binfmt interpreter for hppa
Setting /usr/bin/qemu-riscv32-static as binfmt interpreter for riscv32
Setting /usr/bin/qemu-riscv64-static as binfmt interpreter for riscv64
Setting /usr/bin/qemu-xtensa-static as binfmt interpreter for xtensa
Setting /usr/bin/qemu-xtensaeb-static as binfmt interpreter for xtensaeb
Setting /usr/bin/qemu-microblaze-static as binfmt interpreter for microblaze
Setting /usr/bin/qemu-microblazeel-static as binfmt interpreter for microblazeel
Setting /usr/bin/qemu-or1k-static as binfmt interpreter for or1k

$ ls /proc/sys/fs/binfmt_misc/qemu-aarch64
/proc/sys/fs/binfmt_misc/qemu-aarch64

$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff

$ podman run --rm -t arm64v8/fedora uname -m
aarch64
```

#### 3.2.3 Restoring

multiarch/qemu-user-static should install same content's `/proc/sys/fs/binfmt_misc/qemu-$cpu` files comparing `dnf install qemu-user-static`.
Just in case, run below command to reset the files.

```
$ sudo systemctl restart systemd-binfmt
```

---

## 4 podman/docker buildx

It is to build multi-architecture images from common `Dockerfile`.

### Install docker buildx

Install docker buildx. [8]

`rpms/docker` RPM on Fedora <= 30 is old, "docker buildx" does not support it.
If you want to use "docker buildx", you need to install Docker Community Edition.
See how to install it on Fedora [8].

My environment on Fedora.

```
$ docker --version
Docker version 19.03.0, build aeac9490dc
```

Below installation works with Docker 18.09+ according to the document [8].

```
$ git clone git://github.com/docker/buildx

$ cd buildx

$ make install

...
mkdir -p ~/.docker/cli-plugins
cp bin/buildx ~/.docker/cli-plugins/docker-buildx
```

```
$ docker buildx --help
```

### Building multi-architecture images from common Dockerfile.

docker buildx" does not use binfmt_misc files.

```
$ cat Dockerfile
FROM fedora
RUN uname -m
```

Show `docker buildx build` help.

```
$ docker buildx build --help
...
      --platform stringArray     Set target platform for build
...
```

You can run `docker buildx build --platform` like this.

```
$ docker buildx build --rm -t my-fedora:aarch64 --platform linux/arm64 .
```

Run the image enabling QEMU and binfmt_misc.

```
$ docker run --rm -t my-fedora:aarch64 uname -m
aarch64
```

How build "ppc64le" and "s390x" image, see [10].


### Building multi-architecture images from common Dockerfile - DOCKER_BUILDKIT=1

Enabling `DOCKER_BUILDKIT=1 docker build --platforom` works on many platforms (architecture).

```
$ DOCKER_BUILDKIT=1 docker build --help
...

      --platform string         Set platform if server is multi-platform capable
...
```

```
$ DOCKER_BUILDKIT=1 docker build -t test/fedora-ppc64le --platform linux/ppc64le .
$ docker run --rm -t test/fedora-ppc64le uname -m
ppc64le

$ DOCKER_BUILDKIT=1 docker build -t test/fedora-aarch64 --platform linux/aarch64 .
$ docker run --rm -t test/fedora-aarch64 uname -m
aarch64

$ DOCKER_BUILDKIT=1 docker build -t test/fedora-s390x --platform linux/s390x .
$ docker run --rm -t test/fedora-s390x uname -m
s390x
```

### podman buildx

"podman buildx" has been developed at [11].
It might be going to be not "podman buildx" but "podman build --platform".

---

## 5 References

* [1] DockerHub fedora: https://hub.docker.com/_/fedora
* [2] DockerHub arm64v8/fedora https://hub.docker.com/r/arm64v8/fedora/
* [3] skopeo: https://github.com/containers/skopeo
* [4] Fedora container registory: https://registry.fedoraproject.org/
* [5] https://registry.fedoraproject.org/repo/fedora/tags/
* [6] RHEL architecture specific image URL
  https://github.com/containers/libpod/issues/3063#issuecomment-512935500
* [7] multiarch/qemu-user-static: https://github.com/multiarch/qemu-user-static
* [8] docker buildx: https://github.com/docker/buildx
* [9] Fedora registry.fedoraproject.org/fedora tags
  https://registry.fedoraproject.org/repo/fedora/tags/
* [10] https://github.com/docker/buildx/issues/115
* [11] https://github.com/containers/buildah/issues/1590
