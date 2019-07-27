# 02.system - How do qemu-user-static and binfmt_misc work on Fedora system?

* qemu-user-static
* systemd-binfmt service
* binfmt_misc
* `bin/hello-$cpu`: Architecture spefic binary files.

## 1. Requirements

My environment is like this. This instructions are specified for Fedora.
Even when your architectur is not x86_64, you can refer the instructions.

```
$ uname -m
x86_64

$ cat /etc/fedora-release
Fedora release 30 (Thirty)
```

## 2. Instructions

Initial condition.
Below archictecture specific binary file `01.basic/bin/hello-aarch64` does not work.

```
$ ls /proc/sys/fs/binfmt_misc
register  status

$ file 01.basic/bin/hello-aarch64
01.basic/bin/hello-aarch64: ELF 64-bit LSB executable, ARM aarch64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=fa19c63e3c60463e686564eeeb0937959bd6f559, for GNU/Linux 3.7.0, not stripped, too many notes (256)

$ 01.basic/bin/hello-aarch64
bash: 01.basic/bin/hello-aarch64: cannot execute binary file: Exec format error
```

Install qemu-user-static RPM.

```
$ sudo dnf install qemu-user-static

$ ls /proc/sys/fs/binfmt_misc/ | cat
qemu-aarch64
qemu-aarch64_be
qemu-alpha
qemu-arm
qemu-armeb
qemu-hppa
qemu-m68k
qemu-microblaze
qemu-microblazeel
qemu-mips
qemu-mips64
qemu-mips64el
qemu-mipsel
qemu-mipsn32
qemu-mipsn32el
qemu-or1k
qemu-ppc
qemu-ppc64
qemu-ppc64le
qemu-riscv32
qemu-riscv64
qemu-s390x
qemu-sh4
qemu-sh4eb
qemu-sparc32plus
qemu-xtensa
qemu-xtensaeb
register
status
```

By the way, if you want to remove qemu-user-static completely to the state before `dnf install qemu-user-static`, run below commands.
You need to remove `/proc/sys/fs/binfmt_misc/qemu-$cpu` files by yourself. I reported the issue [1].

```
$ sudo dnf remove qemu-user-static
```

You need to run the command by root user.

```
# find /proc/sys/fs/binfmt_misc -type f -name 'qemu-*' -exec sh -c 'echo -1 > {}' \;
```

So, install `qemu-user-static` without worry. :)

```
$ sudo dnf install qemu-user-static
```

`/proc/sys/fs/binfmt_misc/qemu-$cpu` files are installed by the command.
So, what happened?

```
$ rpm -q qemu-user-static
qemu-user-static-3.1.0-9.fc30.x86_64
```

You can see interpreter files and binfmt.d files that you used in "01.basic" section.

```
$ rpm -ql qemu-user-static
/usr/bin/qemu-aarch64-static
...
/usr/bin/qemu-arm-static
...
/usr/bin/qemu-ppc64le-static
...
/usr/bin/qemu-s390x-static
...
/usr/lib/binfmt.d/qemu-aarch64-static.conf
...
/usr/lib/binfmt.d/qemu-arm-static.conf
...
/usr/lib/binfmt.d/qemu-ppc64le-static.conf
...
/usr/lib/binfmt.d/qemu-s390x-static.conf
...
```

Seeing https://src.fedoraproject.org/rpms/qemu/blob/f30/f/qemu.spec#_1237 , there are scriptlets `%post` and `%postun`.

```
%if %{user_static}
%post user-static
/bin/systemctl --system try-restart systemd-binfmt.service &>/dev/null || :
%postun user-static
/bin/systemctl --system try-restart systemd-binfmt.service &>/dev/null || :
%endif
```

That means

* `%post`: When running `dnf install qemu-user-static`, `/bin/systemctl --system try-restart systemd-binfmt.service` is executed.
* `%postun`: When running `dnf remove qemu-user-static`, `/bin/systemctl --system try-restart systemd-binfmt.service` is executed.

`/bin/systemctl --system try-restart systemd-binfmt.service` means a kind of `systemctl restart systemd-binfmt.service`.

The process can be seprated by `systemctl stop systemd-binfmt` and `systemctl start systemd-binfmt`.


Find systemd-binfmt related files.

```
$ rpm -q systemd
systemd-241-9.gitb67ecf2.fc30.x86_64

$ rpm -ql systemd | grep systemd-binfmt
/usr/lib/systemd/system/sysinit.target.wants/systemd-binfmt.service
/usr/lib/systemd/system/systemd-binfmt.service
/usr/lib/systemd/systemd-binfmt
/usr/share/man/man8/systemd-binfmt.8.gz
/usr/share/man/man8/systemd-binfmt.service.8.gz
```

Here is systemd-binfmt service's config file.
There is no `ExecStop`.

https://github.com/systemd/systemd/blob/v241/units/systemd-binfmt.service.in

```
...
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=@rootlibexecdir@/systemd-binfmt
TimeoutSec=90s
```

Check manuals.

```
$ man systemd-binfmt

$ man binfmt.d
...
SYNOPSIS
       /etc/binfmt.d/*.conf

       /run/binfmt.d/*.conf

       /usr/lib/binfmt.d/*.conf

DESCRIPTION
       At boot, systemd-binfmt.service(8) reads configuration files from the above
       directories to register in the kernel additional binary formats for executables.
...
```

"systemd-binfmt" creates or overrides `/proc/sys/fs/binfmt_misc/qemu-$cpu` files from `/usr/lib/binfmt.d/qemu-$cpu-static.conf` files when running `systemd start systemd-binfmt`.

The created file has **`flags: F`**.

```
$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

The archictecture specific binary file `01.basic/bin/hello-aarch64` works.

```
$ file 01.basic/bin/hello-aarch64
01.basic/bin/hello-aarch64: ELF 64-bit LSB executable, ARM aarch64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=fa19c63e3c60463e686564eeeb0937959bd6f559, for GNU/Linux 3.7.0, not stripped, too many notes (256)

$ 01.basic/bin/hello-aarch64
Hello World!
Endian Type: Little-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}
```

## 3. What we learned

* `qemu-user-static` RPM includes interpreter files: `/usr/bin/qemu-$cpu-static` and binfmt configuration files: `/usr/lib/binfmt.d/qemu-$cpu-static.conf`.
* `dnf install qemu-user-static` RPM installs binfmt_misc files: `/proc/sys/fs/binfmt_misc/qemu-$cpu` from binfmt configuration files: `/usr/lib/binfmt.d/qemu-$cpu-static.conf` through `systemctl start systemd-binfmt`.
* When you want to remove the installed binfmt_misc files: `/proc/sys/fs/binfmt_misc/qemu-$cpu`, you need to remove the files manually by root user.
* binfmt_misc files: `/proc/sys/fs/binfmt_misc/qemu-$cpu` are installed as `flags: F` (See "01.basic" for the meaning of `flags: F`).

## 4. References

* [1] qemu-user-static: qemu-user-static works even after "dnf remove qemu-user-static"
  https://bugzilla.redhat.com/show_bug.cgi?id=1732178
* [2] systemd: "systemctl stop systemd-binfmt" should remove the registered entries?
  https://github.com/systemd/systemd/issues/13129
