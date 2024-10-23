# Base image
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf

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
