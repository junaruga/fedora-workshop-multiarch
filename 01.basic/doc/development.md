# Development

## How to create architecture specific binaries

For a x86_64 binary,

```
$ sudo dnf install gcc make glibc-static

$ make
```

```
$ ls bin/hello-x86_64
bin/hello-x86_64

$ bin/hello-x86_64
Hello World!
Endian Type: Little-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}

$ file bin/hello-x86_64
bin/hello-x86_64: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, for GNU/Linux 3.2.0, BuildID[sha1]=788d849f0d6a08f3d025de5706fec5f5f5e91513, not stripped, too many notes (256)
```

For different architectures binaries, we can use mock command, referring the document [1].

For aarch64

```
$ vi ~/.config/mock.cfg
...
config_opts['plugin_conf']['bind_mount_opts']['dirs'].append(('/home/jaruga/git/fedora-workshop-multiarch', '/mnt/fedora-workshop-multiarch' ))
...

$ mock -r fedora-rawhide-aarch64 --forcearch=aarch64 --scrub=all
$ mock -r fedora-rawhide-aarch64 --forcearch=aarch64 shell
$ mock -r fedora-rawhide-aarch64 --forcearch=aarch64 -i gcc make glibc-static
$ mock -r fedora-rawhide-aarch64 --forcearch=aarch64 shell

[chroot]# su - mockbuild
[chroot]$ cd /mnt/fedora-workshop-multiarch/01.basic
[chroot]$ make
```

```
[chroot]$ ls bin/hello-aarch64
bin/hello-aarch64

[chroot]$ file bin/hello-aarch64
bin/hello-aarch64: ELF 64-bit LSB executable, ARM aarch64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=fa19c63e3c60463e686564eeeb0937959bd6f559, for GNU/Linux 3.7.0, not stripped, too many notes (256)
```

For s390x

```
$ mock -r fedora-rawhide-s390x --forcearch=s390x --scrub=all
$ mock -r fedora-rawhide-s390x --forcearch=s390x shell
$ mock -r fedora-rawhide-s390x --forcearch=s390x -i gcc make glibc-static
$ mock -r fedora-rawhide-s390x --forcearch=s390x shell
```

For arm7hl

```
$ mock -r fedora-rawhide-armhfp --forcearch=armv7hl --scrub=all
$ mock -r fedora-rawhide-armhfp --forcearch=armv7hl shell
$ mock -r fedora-rawhide-armhfp --forcearch=armv7hl -i gcc make glibc-static
$ mock -r fedora-rawhide-armhfp --forcearch=armv7hl shell
```

For ppc64le

```
$ mock -r fedora-rawhide-ppc64le --forcearch=ppc64le --scrub=all
$ mock -r fedora-rawhide-ppc64le --forcearch=ppc64le shell
$ mock -r fedora-rawhide-ppc64le --forcearch=ppc64le -i gcc make glibc-static
$ mock -r fedora-rawhide-ppc64le --forcearch=ppc64le shell
```

## References

* [1] mock: https://github.com/rpm-software-management/mock/wiki/Feature-forcearch
