ARG BASE_IMAGE
FROM ${BASE_IMAGE}

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
    zlib1g-dev \
    liblzma-dev \ 
    git \
    texinfo \
    musl-tools \
    && rm -rf /var/lib/apt/lists/*

# Build Universal Ctags
WORKDIR /tmp
RUN git clone https://github.com/universal-ctags/ctags.git && \
    cd ctags && \
    ./autogen.sh && \
    ./configure CFLAGS="-static" CXXFLAGS="-w" LDFLAGS="-static" --enable-static --disable-iconv && \
    make -j$(nproc) && \
    make install

# Build GNU Global -> static build doesn't work
WORKDIR /tmp
RUN wget -q https://ftp.gnu.org/pub/gnu/global/global-${GLOBAL_VERSION}.tar.gz && \
    tar -xzf global-${GLOBAL_VERSION}.tar.gz && \
    cd global-${GLOBAL_VERSION} && \
    CC=musl-gcc ./configure --with-universal-ctags=/tools/usr/local/bin/ctags --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install

# Build GDB -> use rocGDB instead
#WORKDIR /tmp
#RUN wget -q http://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.gz && \
#    tar -xzf gdb-${GDB_VERSION}.tar.gz && \
#    cd gdb-${GDB_VERSION} && \
#    ./configure CFLAGS="-w -Wno-deprecated -static" CXXFLAGS="-w" LDFLAGS="-static" --enable-static --disable-shared && \
#    make -j$(nproc) && \
#    make DESTDIR=/tools install
