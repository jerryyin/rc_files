# Base image
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf

# Build GNU Global
# static build doesn't work
WORKDIR /tmp
RUN wget -q https://ftp.gnu.org/pub/gnu/global/global-${GLOBAL_VERSION}.tar.gz && \
    tar -xzf global-${GLOBAL_VERSION}.tar.gz && \
        cd global-${GLOBAL_VERSION} && \
            ./configure --with-universal-ctags=/usr/local/bin/ctags CFLAGS="-w -Wno-deprecated" CXXFLAGS="-w" && \
                make -j$(nproc) && make install

# lightweight setup script
WORKDIR /root
RUN git clone https://github.com/jerryyin/scripts.git && \
    bash scripts/docker/init.sh

ARG SERVICE_NAME
RUN if [ "$SERVICE_NAME" = "rocmlir" ]; then \
      echo "Running additional setup for rocmlir"; \
      #bash scripts/docker/init_mlir.sh; \
    elif [ "$SERVICE_NAME" = "triton" ]; then \
      echo "Running additional setup for triton"; \
      #bash scripts/docker/init_triton.sh; \
    else \
      echo "No specific setup for $SERVICE_NAME"; \
    fi
