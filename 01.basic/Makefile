ARCH = $(shell rpm -q rpm --qf "%{arch}")
# ARCH = $(shell uname -m)
TARGET = bin/hello-$(ARCH)

# gcc -static is for static compile.
# Run "dnf install glibc-static" in advance.
all :
	@echo "Building on $(ARCH)."
	gcc -o $(TARGET) src/main.c -static
.PHONY : all

clean :
	rm -rf src/*.o $(TARGET)
.PHONY : clean

test : all
	file $(TARGET)
	$(TARGET)
.PHONY : test
