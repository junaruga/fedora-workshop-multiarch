# 01.basic - qemu-user-static and binfmt_misc

Table of contents

* 1 qemu-user-static
* 2 qemu-user-static and binfmt_misc

Let's understand qemu-user-static and binfmt_misc through experiments.

---

## 1 qemu-user-static

### 1.1 Introduction

What is qemu-user-static?

* qemu-user-static is QEMU [1]'s "user" mode emulation "static" binaries.
* QEMU is a cpu emulator.
* User mode is one of "user mode vs kernel mode". That is a application process emulation. QEMU has 2 modes, that are user mode emulation and file system emulation.
* Static binary is static built binary that does not link with shared libraries. See `man gcc` "-static" option.


On Fedora, qemu-user-static RPM is qemu RPM's user-static sub package. [2]

According to the qemu.spec

```
Summary: QEMU user mode emulation of qemu targets static build
...
%description user-static
This package provides the user mode emulation of qemu targets built as
static binaries
```

### 1.2 Files

2 kind of files in this repository to keep in mind.

* Interpreter files: `interpreter/qemu-$cpu-static` copied from ones in `qemu-user-static` RPM.
* Architecture spefic binary files: `bin/hello-$cpu` built by `gcc -static` See `Makefile`.

### 1.3 Experiment

#### 1.3.1 Preparation

In this document the host OS architecture is "x86_64". Buf if your host OS is a different architecture, you can execute the experiement as well.

```
$ uname -m
x86_64
```

Check files on `/proc/sys/fs/binfmt_misc`.

Are there only `register` and `status` files on it?

```
$ ls /proc/sys/fs/binfmt_misc
register  status
```

Or are there `/proc/sys/fs/binfmt_misc/qemu-$cpu` files?
If Fedora `qemu-user-static` RPM is installed, you see below files. You still do not need to install the `qemu-user-static` RPM.

```
$ ls /proc/sys/fs/binfmt_misc
qemu-aarch64     qemu-m68k          qemu-mipsel     qemu-ppc64le  qemu-sparc32plus
qemu-aarch64_be  qemu-microblaze    qemu-mipsn32    qemu-riscv32  qemu-xtensa
qemu-alpha       qemu-microblazeel  qemu-mipsn32el  qemu-riscv64  qemu-xtensaeb
qemu-arm         qemu-mips          qemu-or1k       qemu-s390x    register
qemu-armeb       qemu-mips64        qemu-ppc        qemu-sh4      status
qemu-hppa        qemu-mips64el      qemu-ppc64      qemu-sh4eb
```

If `/proc/sys/fs/binfmt_misc/qemu-$cpu` files exist, remove those for below experiment for now. Do not worry, you can restore it by `systemctl restart systemd-binfmt` if `qemu-user-static` RPM is installed or `dnf install qemu-user-static` if it is not installed.

Run below command to remove `/proc/sys/fs/binfmt_misc/qemu-*` files.
You need to run by root user. `sudo` is not allowed for the command.

```
$ sudo su -

# find /proc/sys/fs/binfmt_misc -type f -name 'qemu-*' -exec sh -c 'echo -1 > {}' \;

$ ls /proc/sys/fs/binfmt_misc
register  status
```

#### 1.3.2 Execution

In this case, I am running "aarch64" binary on the interpriter on the host architecture "x86_64".
If your host OS have a different architecture, you can run other architecture binaries as well, as we prepared "aarch64" (ARM 64-bit), "armv7hl" (ARM 32-bit), "ppc64le", "s390x" interpriters and binaries in this repository.

```
$ uname -m
x86_64

$ file bin/hello-aarch64
bin/hello-aarch64: ELF 64-bit LSB executable, ARM aarch64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=fa19c63e3c60463e686564eeeb0937959bd6f559, for GNU/Linux 3.7.0, not stripped, too many notes (256)

$ bin/hello-aarch64
bash: bin/hello-aarch64: cannot execute binary file: Exec format error
```

The interpreter `qemu-aarch64-static` runs the arch64 binary `bin/hello-aarch64`.

```
$ interpreter/qemu-aarch64-static bin/hello-aarch64
Hello World!
Endian Type: Little-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}
```

#### 1.3.3 Restoring

If you want to move on next part, you do not have to run below command.
If you want to finish your work, then restore your environment, run below command.

```
$ sudo systemctl restart systemd-binfmt
```

If `qemu-user-static` RPM is installed, you see below `qemu-$cpu` files.

```
$ ls /proc/sys/fs/binfmt_misc
qemu-aarch64     qemu-m68k          qemu-mipsel     qemu-ppc64le  qemu-sparc32plus
qemu-aarch64_be  qemu-microblaze    qemu-mipsn32    qemu-riscv32  qemu-xtensa
qemu-alpha       qemu-microblazeel  qemu-mipsn32el  qemu-riscv64  qemu-xtensaeb
qemu-arm         qemu-mips          qemu-or1k       qemu-s390x    register
qemu-armeb       qemu-mips64        qemu-ppc        qemu-sh4      status
qemu-hppa        qemu-mips64el      qemu-ppc64      qemu-sh4eb
```

### 1.4 Conclusion

* `qemu-$cpu-static` can run architecture specific binary.


---

## 2 - qemu-user-static and binfmt_misc

### 2.1 Introduction

You learned qemu-user-static on previous part "1 qemu-user-static".
Let's see how qemu-user-static works with binfmt_misc. You still do not need to install `qemu-user-static` RPM.


binfmt_misc is binary formats miscellaneous.

According to document [3], it is a kernel support for miscellaneous (your favourite) binary formats.
Keep in mind that this is a kernel feature.
For now, just remember it is about below special files on `/proc/sys/fs/binfmt_misc`.

You see the binfmt_misc is mounted on your system on your Fedora.

```
$ mount | grep binfmt_misc
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=44,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=19096)
binfmt_misc on /proc/sys/fs/binfmt_misc type binfmt_misc (rw,relatime)
```

If you are interested in the C language level manual, see [4]. Do not ask me about the content of the manual. :)


### 2.2 Files

In this part, we use additional below files.

* binfmt_misc files: `/proc/sys/fs/binfmt_misc/qemu-$cpu`

There are `binfmt.d/qemu-$cpu-static.conf` files copied from ones in `qemu-user-static` RPM. But we do not use the files directly. The files are a memo of binary formats for someone who do not install `qemu-user-static` on the environment.

### 2.3 Experiment

#### 2.3.1 Preparation

It's same with "1.3.1 Preparation".
If `/proc/sys/fs/binfmt_misc/qemu-$cpu` files exist not like below state, let's remove those following "1.3.1 Preparation".
You still do not need to install `qemu-user-static` RPM in this part.

```
$ ls /proc/sys/fs/binfmt_misc
register  status
```

#### 2.3.2 Execution

We execute 2 experiments.

* A case of adding binary format with empty flags.
* A case of adding binary format with `flags: F`.

It's important to understand the difference of those behaviors, to debug qemu-user-static on more complex cases.


##### 2.3.2.1 Case: binary format with empty flags

Run below command to add binary format entry.
The format is `:$name:$type:$offset:$magic:$mask:$interpreter:$flags` [2].
In this page, just keep in mind 2 items in the format.

* `name`: It is used for the file name `/proc/sys/fs/binfmt_misc/$name`.
* `interpreter`: File path to a interpreter.
* `flags`: We explanin about 2 types of flags: empty or `F` in this page.


The interpreter `/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-aarch64-static`'s existantce is **not checked** when running the command to register the binary format entry.

```
# echo ":my-qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-aarch64-static:" > /proc/sys/fs/binfmt_misc/register
```

```
$ ls -l /proc/sys/fs/binfmt_misc
total 0
-rw-r--r-- 1 root root 0 Jul 26 19:07 my-qemu-aarch64
--w------- 1 root root 0 Jul 26 19:07 register
-rw-r--r-- 1 root root 0 Jul 23 16:23 status
```

```
$ cat /proc/sys/fs/binfmt_misc/my-qemu-aarch64
enabled
interpreter /home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-aarch64-static
flags: 
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```

```
$ bin/hello-aarch64
Hello World!
Endian Type: Little-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}
```

When renaming the interpreter, `bin/hello-aarch64` shows "No such file or directory".
When a value of flags is empty, the interpreter is **checked** at run time.

```
$ mv interpreter/qemu-aarch64-static interpreter/qemu-aarch64-static.tmp

$ ls interpreter/qemu-aarch64-static
ls: cannot access 'interpreter/qemu-aarch64-static': No such file or directory

$ bin/hello-aarch64
bash: bin/hello-aarch64: No such file or directory

$ mv interpreter/qemu-aarch64-static.tmp interpreter/qemu-aarch64-static

$ bin/hello-aarch64
Hello World!
Endian Type: Little-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}
```

Run below command to remove a binary format entry.

```
# ls /proc/sys/fs/binfmt_misc/
my-qemu-aarch64  register  status

# echo -1 > /proc/sys/fs/binfmt_misc/my-qemu-aarch64

# ls /proc/sys/fs/binfmt_misc
register  status
```

```
$ bin/hello-aarch64
bash: bin/hello-aarch64: cannot execute binary file: Exec format error
```

##### 2.3.2.2 Case of `flags: F`


Run below command to add binary format entry with **`flags: F`**.
The interpreter `/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-s390x-static`'s existantce is **checked** when running the command to register the binary format entry.

```
$ mv interpreter/qemu-s390x-static interpreter/qemu-s390x-static.tmp

$ ls interpreter/qemu-s390x-static
ls: cannot access 'interpreter/qemu-s390x-static': No such file or directory
```

```
$ ls /proc/sys/fs/binfmt_misc
register  status

# echo ":my-qemu-s390x-F:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x16:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-s390x-static:F" > /proc/sys/fs/binfmt_misc/register
-bash: echo: write error: No such file or directory

# echo $?
1

$ ls /proc/sys/fs/binfmt_misc
register  status
```

```
$ mv interpreter/qemu-s390x-static.tmp interpreter/qemu-s390x-static
```

```
$ ls /proc/sys/fs/binfmt_misc
register  status

# echo ":my-qemu-s390x-F:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x16:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-s390x-static:F" > /proc/sys/fs/binfmt_misc/register

$ ls -l /proc/sys/fs/binfmt_misc
total 0
-rw-r--r-- 1 root root 0 Jul 26 19:41 my-qemu-s390x-F
--w------- 1 root root 0 Jul 26 19:41 register
-rw-r--r-- 1 root root 0 Jul 23 16:23 status

# cat /proc/sys/fs/binfmt_misc/my-qemu-s390x-F
enabled
interpreter /home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-s390x-static
flags: F
offset 0
magic 7f454c4602020100000000000000000000020016
mask ffffffffffffff00fffffffffffffffffffeffff
```

```
$ bin/hello-s390x
Hello World!
Endian Type: Big-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}
```

When a value of flags is **`flags: F`**, the interpreter is **not checked** at run time.

```
$ mv interpreter/qemu-s390x-static interpreter/qemu-s390x-static.tmp

$ ls interpreter/qemu-s390x-static
ls: cannot access 'interpreter/qemu-s390x-static': No such file or directory

$ bin/hello-s390x
Hello World!
Endian Type: Big-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}


$ mv interpreter/qemu-s390x-static.tmp interpreter/qemu-s390x-static
```

```
# ls /proc/sys/fs/binfmt_misc
my-qemu-s390x-F  register  status

# echo -1 > /proc/sys/fs/binfmt_misc/my-qemu-s390x-F

# ls /proc/sys/fs/binfmt_misc
register  status
```

#### 2.3.3 Restoring

Run below command to restore if `qemu-user-static` RPM is installed and you want to restore `/proc/sys/fs/binfmt_misc/qemu-$cpu` files. The process is almost same with "1.3.3 Restoring".

```
$ sudo systemctl restart systemd-binfmt
```

### 2.4 Conclusion

* `# echo ":$name:$type:$offset:$magic:$mask:$interpreter:$flags" > /proc/sys/fs/binfmt_misc/register` to add a binary format entry.
* `# echo -1 > /proc/sys/fs/binfmt_misc/qemu-$cpu` to remove a qemu binary format entry.
* If the entry file's `flags` is empty, the exsistance of the interpreter is checked at run time.
* If the entry file's `flags` is `flags: F`, the existance of the interpreter is checked when registering the entry.

---

## 3 References

* [1] QEMU: https://www.qemu.org/
* [2] Fedora qemu RPM: https://src.fedoraproject.org/rpms/qemu
* [3] binfmt_misc: https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html
* [4] binfmt_misc C language level manual: https://lwn.net/Articles/630727/

