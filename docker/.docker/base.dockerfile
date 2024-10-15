# Base image
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf

#include tools.dockerfile
# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV GLOBAL_VERSION=6.6.13
ENV GDB_VERSION=15.1

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libgmp-dev \
    autoconf \
    automake \
    libtool \
    wget \
    pkg-config \
    libncurses5-dev \
    libmpc-dev \
    python3-docutils \
    libseccomp-dev \
    libjansson-dev \
    libyaml-dev \
    libxml2-dev \
    git \
    texinfo \
    && rm -rf /var/lib/apt/lists/*

# Build Universal Ctags
WORKDIR /tmp
RUN git clone https://github.com/universal-ctags/ctags.git && \
    cd ctags && \
    ./autogen.sh && \
    ./configure CFLAGS="-w -Wno-deprecated" CXXFLAGS="-w" && \
    make -j$(nproc) && make install

# Build GNU Global
WORKDIR /tmp
RUN wget -q https://ftp.gnu.org/pub/gnu/global/global-${GLOBAL_VERSION}.tar.gz && \
    tar -xzf global-${GLOBAL_VERSION}.tar.gz && \
    cd global-${GLOBAL_VERSION} && \
    ./configure --with-universal-ctags=/usr/local/bin/ctags CFLAGS="-w -Wno-deprecated" CXXFLAGS="-w" && \
    make -j$(nproc) && make install

# Build GDB
WORKDIR /tmp
RUN wget -q http://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.gz && \
    tar -xzf gdb-${GDB_VERSION}.tar.gz && \
    cd gdb-${GDB_VERSION} && \
    ./configure CFLAGS="-w -Wno-deprecated" CXXFLAGS="-w" && \
    make -j$(nproc) && make install

# lightweight setup script
WORKDIR /root
RUN git clone https://github.com/jerryyin/scripts.git && \
    bash scripts/docker/init.sh

ARG SERVICE_NAME
RUN if [ "$SERVICE_NAME" = "rocmlir" ]; then \
      echo "Running additional setup for rocmlir"; \
      bash scripts/docker/init_mlir.sh; \
    elif [ "$SERVICE_NAME" = "triton" ]; then \
      echo "Running additional setup for triton"; \
      bash scripts/docker/init_triton.sh; \
    else \
      echo "No specific setup for $SERVICE_NAME"; \
    fi
