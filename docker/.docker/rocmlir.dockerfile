# Base image
FROM rocm/mlir:latest

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf

#include tools.dockerfile

# lightweight setup script
WORKDIR /root
RUN git clone https://github.com/jerryyin/scripts.git && \
    bash scripts/docker/init.sh
