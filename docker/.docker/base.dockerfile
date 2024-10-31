# Base image
ARG BASE_IMAGE
FROM ${BASE_IMAGE:-ubuntu:22.04}

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf

# lightweight setup script
WORKDIR /root
RUN apt-get update && apt-get -y install git && \
    git clone https://github.com/jerryyin/scripts.git && \
    bash scripts/docker/init_min.sh

ARG SERVICE_NAME
RUN if [ "$SERVICE_NAME" = "rocmlir" ]; then \
      echo "Running additional setup for rocmlir"; \
      bash scripts/docker/init_mlir.sh; \
    elif [ "$SERVICE_NAME" = "triton" ]; then \
      echo "Running additional setup for triton"; \
      bash scripts/docker/init_triton.sh; \
    elif [ "$SERVICE_NAME" = "iree" ]; then \
      echo "Running additional setup for iree"; \
      bash scripts/docker/init_iree.sh; \
    else \
      echo "No specific setup for $SERVICE_NAME"; \
    fi
