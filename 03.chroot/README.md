# 03.chroot - qemu-user-static, binfmt_misc and chroot on Fedora

## 1 Introduction

`qemu-user-static` works on chroot environment.

Let's see how it works. `mock` command is good example to see it. `mock` command uses chroot to enable the mock environment internally. The specified architecture's binary files are installed to the chroot environment when using `mock --forcearch $arch (cpu)` option. [1]

## 2 Experiment

```
$ uname -m
x86_64
```

If you have not installed `qemu-user-static` RPM, install it.

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

You can use the detault mock configuratoin files `/etc/mock/fedora-rawhide-$cpu.cfg` without any change.

```
$ mock -r fedora-rawhide-aarch64 --forcearch=aarch64 shell
```

```
<mock-chroot> sh-5.0# uname -m
aarch64

<mock-chroot> sh-5.0# exit
```

`/var/lib/mock/fedora-rawhide-aarch64/root` is the root directory used for the chroot environment.

```
$ ls /var/lib/mock/fedora-rawhide-aarch64/root
bin@   builddir/  etc/   .initialized  lib64@  mnt/  proc/  run/   srv/  tmp/  var/
boot/  dev/       home/  lib@          media/  opt/  root/  sbin@  sys/  usr/
```

```
$ ls /var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/uname
/var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/uname*

$ file /var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/uname
/var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/uname: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=4e21c4458f4d12d79ba73e24c24b40b4d085e70c, for GNU/Linux 3.7.0, stripped
```

Remember this `/proc/sys/fs/binfmt_misc/qemu-aarch64` file again. flags setting is `flags: F`. That means interpreter is checked when registering binary format entry, but it is not checked at run time.

```
$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
...
```

```
$ ls /var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/qemu-aarch64-static
ls: cannot access '/var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/qemu-aarch64-static': No such file or directory

$ sudo chroot /var/lib/mock/fedora-rawhide-aarch64/root /usr/bin/uname -m
aarch64
```

Now update `/proc/sys/fs/binfmt_misc/qemu-aarch64` file from `flags: F` to `flags: `(empty flag).

```
$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

```
# echo -1 > /proc/sys/fs/binfmt_misc/qemu-aarch64
# echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:" > /proc/sys/fs/binfmt_misc/register
```

```
$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: 
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

Below command is failed, because when the flag F is not set, the interpreter `/usr/bin/qemu-aarch64-static` is needed to exist inside of the chroot to run the emulation.

```
$ sudo chroot /var/lib/mock/fedora-rawhide-aarch64/root /usr/bin/uname -m
chroot: failed to run command ‘/usr/bin/uname’: No such file or directory
```

`qemu-aarch64-static` does not exist.

```
$ ls /var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/qemu-aarch64-static
ls: cannot access '/var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/qemu-aarch64-static': No such file or directory
```

But after copying `qemu-aarch64-static` binary to chroot, below `sudo chroot ...` works.

```
$ sudo cp -p /usr/bin/qemu-aarch64-static /var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/

$ ls /var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/qemu-aarch64-static
/var/lib/mock/fedora-rawhide-aarch64/root/usr/bin/qemu-aarch64-static*

$ sudo chroot /var/lib/mock/fedora-rawhide-aarch64/root /usr/bin/uname -m
aarch64
```

As a post procedure, let's restore `/proc/sys/fs/binfmt_misc/qemu-aarch64` to default content by running `systemctl restart systemd-binfmt`.

```
$ sudo systemctl restart systemd-binfmt

$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

### Host OS /proc/sys/fs/binfmt_misc files used on chroot environment?

There is no file under `/var/lib/mock/fedora-rawhide-aarch64/root/proc`.

```
$ ls /var/lib/mock/fedora-rawhide-aarch64/root/proc
```

There is no file under `/proc/sys/fs/binfmt_misc/`.

```
<mock-chroot> sh-5.0# ls /proc/sys/fs/binfmt_misc/
```

I assume that `/proc` is commonly used by host OS and chroot environment.
But I am not sure. Please tell me if you know something about it. :)

## 3 References

* [1] mock forcearch feature: https://github.com/rpm-software-management/mock/wiki/Feature-forcearch
