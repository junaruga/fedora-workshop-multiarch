ARG BASE_IMAGE=fedora
FROM ${BASE_IMAGE}

RUN uname -m
RUN rpm -q rpm --qf "%{arch}\n"
# Set "--forcearch" option in a case of that RPM package arch and "uname -m"
# are different.
# Ex. "uname -m": aarch64, "package arch": armv7hl
RUN ARCH=$(rpm -q rpm --qf "%{arch}") && \
  dnf -y --forcearch "${ARCH}" upgrade && \
  dnf -y --forcearch "${ARCH}" install \
  # Required packages for this application.
  file \
  gcc \
  glibc-static \
  make \
  # Optional packages to show an example.
  python3 && \
  dnf clean all
RUN gcc --version
RUN python3 --version
WORKDIR /work
COPY . .
