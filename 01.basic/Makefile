ARCH = $(shell rpm -q rpm --qf "%{arch}")
# ARCH = $(shell uname -m)

# gcc -static is for static compile.
# Run "dnf install glibc-static" in advance.
all :
	@echo "Building on $(ARCH)."
	gcc -o bin/hello-$(ARCH) src/main.c -static
.PHONY : all

test :
	file bin/hello-$(ARCH)
	bin/hello-$(ARCH)
.PHONY : test

clean :
	rm -rf src/*.o bin/hello-$(ARCH)
.PHONY : clean
