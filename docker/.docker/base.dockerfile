# Base image
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf

# lightweight setup script
WORKDIR /root

# Debug build scripts
#COPY scripts scripts

RUN apt-get update && apt-get -y install git && \
    git clone https://github.com/jerryyin/scripts.git

RUN bash scripts/docker/init_min.sh

ARG SERVICE_NAME  
RUN echo "Service name is: $SERVICE_NAME"; \  
    if [ "$SERVICE_NAME" = "rocmlir" ]; then \  
      echo "Running additional setup for rocmlir"; \  
      bash scripts/docker/init_mlir.sh; \  
    elif [ "$SERVICE_NAME" = "triton" ]; then \  
      echo "Running additional setup for triton"; \  
      bash scripts/docker/init_triton.sh; \  
    elif [ "$SERVICE_NAME" = "iree" ]; then \  
      echo "Running additional setup for iree"; \  
      bash scripts/docker/init_iree.sh; \  
    elif [ "$SERVICE_NAME" = "base" ]; then \  
      echo "Running no additional setup for base"; \  
    else \  
      echo "No specific setup for $SERVICE_NAME"; \  
    fi  

