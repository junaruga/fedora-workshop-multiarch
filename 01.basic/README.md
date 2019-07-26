# 01.basic - qemu-user-static and binfmt_misc

Let's understand qemu-user-static [1] and binfmt_misc [2][3] through a experiment.

* Interpreter files: `/usr/bin/qemu-$cpu-static`
* binfmt_misc files: `/proc/sys/fs/binfmt_misc/qemu-$cpu`
* Archictecture specific binary files

## 1. What is qemu-user-static?

qemu RPM's user-static sub package. [1]

According to qemu.spec

```
Summary: QEMU user mode emulation of qemu targets static build
...
%description user-static
This package provides the user mode emulation of qemu targets built as
static binaries
```

## 2. What is binfmt_misc?

See [2][3].
binfmt_misc = Binary formats miscellaneous.

According to [2].

Kernel Support for miscellaneous (your favourite) Binary Formats.

```
/proc/sys/fs/binfmt_misc/
  register
  status
```

## 3. 3 Characters

There are 3 kind of files to keep in mind.

* `interpreter/qemu-$cpu-static` files.
* binfmt_misc files: `/proc/sys/fs/binfmt_misc/qemu-$cpu`
* `bin/hello-$cpu`: Architecture spefic binary files.


## 4. Experiment

### 4.1. Preparation

**Note: If you are not familar with command line, DO NOT run below commands. some commands to modify `/proc/sys/fs/binfmt_misc` state is to affect your system. Please do it by own responsibility.**

Reset current status.

```
$ sudo dnf remove qemu-user-static

$ rpm -q qemu-user-static
package qemu-user-static is not installed
```

Open another terminal to run command by root user.
We can not use "sudo" to operate `/proc/sys/fs/binfmt_misc/*` files.
Below command is to remove `/proc/sys/fs/binfmt_misc/qemu-*` files.
Do not worry you can install those again when you run `dnf install qemu-user-static`.

```
$ ls /proc/sys/fs/binfmt_misc/qemu-* | cat
/proc/sys/fs/binfmt_misc/qemu-aarch64
/proc/sys/fs/binfmt_misc/qemu-aarch64_be
/proc/sys/fs/binfmt_misc/qemu-alpha
...

```

```
$ sudo su -

# find /proc/sys/fs/binfmt_misc -type f -name 'qemu-*' -exec sh -c 'echo -1 > {}' \;

# ls -l /proc/sys/fs/binfmt_misc
total 0
--w------- 1 root root 0 Jul 25 11:33 register
-rw-r--r-- 1 root root 0 Jul 23 16:23 status
```

### 4.2. Understanding files used in this repository

#### 4.2.1. `bin/hello-$cpu`: Architecture spefic binary files.

The files are compiled binaries by `Makefile` and `src/*.[ch]` on each architecture.

```
$ uname -m
x86_64
```

```
$ file bin/hello-aarch64
bin/hello-aarch64: ELF 64-bit LSB executable, ARM aarch64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=fa19c63e3c60463e686564eeeb0937959bd6f559, for GNU/Linux 3.7.0, not stripped, too many notes (256)

$ file bin/hello-armv7hl
bin/hello-armv7hl: ELF 32-bit LSB executable, ARM, EABI5 version 1 (GNU/Linux), statically linked, BuildID[sha1]=dbe96ac0190fdecea970b57ee6f75ad67fbdf255, for GNU/Linux 3.2.0, not stripped, too many notes (256)

$ file bin/hello-ppc64le
bin/hello-ppc64le: ELF 64-bit LSB executable, 64-bit PowerPC or cisco 7500, version 1 (GNU/Linux), statically linked, BuildID[sha1]=e3a66983a7862072e719a702ca2117e8d4790946, for GNU/Linux 3.10.0, not stripped, too many notes (256)

$ file bin/hello-s390x
bin/hello-s390x: ELF 64-bit MSB executable, IBM S/390, version 1 (GNU/Linux), statically linked, BuildID[sha1]=084199341ffb18cc63189904ff222e9978c74313, for GNU/Linux 3.2.0, not stripped, too many notes (256)

$ file bin/hello-x86_64
bin/hello-x86_64: ELF 64-bit LSB executable, x86-64, version 1 (GNU/Linux), statically linked, for GNU/Linux 3.2.0, BuildID[sha1]=788d849f0d6a08f3d025de5706fec5f5f5e91513, not stripped, too many notes (256)
```

```
$ bin/hello-aarch64
bash: bin/hello-aarch64: cannot execute binary file: Exec format error

$ bin/hello-armv7hl
bash: bin/hello-armv7hl: cannot execute binary file: Exec format error

$ bin/hello-ppc64le
bash: bin/hello-ppc64le: cannot execute binary file: Exec format error

$ bin/hello-s390x
bash: bin/hello-s390x: cannot execute binary file: Exec format error

$ bin/hello-x86_64
Hello World!
Endian Type: Little-endian
Bit: 64-bit
Sizeof {int, long, long long, void*, size_t, off_t}: {4, 8, 8, 8, 8, 8}
```


#### 4.2.2. `binfmt.d/qemu-$cpu-static.conf` files.

Files copied from qemu-user-static RPM `/usr/lib/binfmt.d/qemu-$cpu-static.conf`.


#### 4.2.3. `interpreter/qemu-$cpu-static` files.

Files copied from qemu-user-static RPM `/usr/bin/qemu-$cpu-static`.


### 4.3. Add and remove binfmt_misc entries.

#### 4.3.1. Case of "flags empty"

Run below command to add binary format entry.
The format is `:$name:$type:$offset:$magic:$mask:$interpreter:$flags` [2].
In this page, just keep in mind 2 items in the format.

* `name`: It is used for the file name `/proc/sys/fs/binfmt_misc/$name`.
* `interpreter`: File path to a interpreter.
* `flags`: We explanin about 2 types of flags: empty or `F` in this page.


The interpreter `/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-aarch64-static`'s existantce is **not checked** when running the command.

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

#### 4.3.2. Case of "flags: F"


Run below command to add binary format entry withi **`flags: F`**.
The interpreter `/home/jaruga/git/fedora-workshop-multiarch/01.basic/interpreter/qemu-s390x-static`'s existantce is **checked** when running the command.

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

## 4.4. What we learned

* `# echo ":$name:$type:$offset:$magic:$mask:$interpreter:$flags" > /proc/sys/fs/binfmt_misc/register` to add a binary format entry.
* `# echo -1 > /proc/sys/fs/binfmt_misc/qemu-$cpu` to remove a qemu binary format entry.
* If the entry file's `flags` is empty, the exsistance of the interpreter is checked at run time.
* If the entry file's `flags` is `flags: F`, the existance of the interpreter is checked when registering the entry.

## 4.5. References

* [1] qemu-user-static: qemu's sub package user-static: https://src.fedoraproject.org/rpms/qemu
* [2] binfmt_misc manual: https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html
* [3] binfmt_misc C language level manual: https://lwn.net/Articles/630727/
