ARG BASE_IMAGE=fedora
FROM ${BASE_IMAGE}

WORKDIR /work
COPY . .
RUN uname -m
RUN rpm -q rpm --qf "%{arch}\n"
RUN ARCH=$(rpm -q rpm --qf "%{arch}") && \
  dnf -y --forcearch "${ARCH}" upgrade && \
  dnf -y --forcearch "${ARCH}" install \
  # Required packages
  file \
  gcc \
  glibc-static \
  make \
  # Optional packages
  python3 && \
  dnf clean all
RUN gcc --version
RUN python3 --version
