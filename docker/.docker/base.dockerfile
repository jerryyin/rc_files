# Base image
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

USER root
WORKDIR /root

RUN printf 'Acquire::http::proxy "%s";\nAcquire::https::proxy "%s";\n' "${HTTP_PROXY:-}" "${HTTPS_PROXY:-}" > /etc/apt/apt.conf

# lightweight setup script
WORKDIR /root

# Debug build scripts
#COPY scripts scripts 
#RUN bash scripts/docker/env/min.sh

RUN apt-get update && apt-get -y install wget && \
    wget -O /tmp/min.sh https://raw.githubusercontent.com/jerryyin/scripts/master/docker/env/min.sh && \
    bash /tmp/min.sh

ARG SERVICE_NAME  
RUN echo "Service name is: $SERVICE_NAME"; \  
    if [ "$SERVICE_NAME" = "rocmlir" ]; then \  
      echo "Running additional setup for rocmlir"; \  
      bash scripts/docker/env/mlir.sh; \  
    elif [ "$SERVICE_NAME" = "triton" ]; then \  
      echo "Running additional setup for triton"; \  
      bash scripts/docker/env/iree.sh; \  
      bash scripts/docker/workspace/triton.sh; \  
    elif [ "$SERVICE_NAME" = "iree" ]; then \  
      echo "Running additional setup for iree"; \  
      bash scripts/docker/env/iree.sh; \  
      echo "Setting up IREE workspace"; \  
      bash scripts/docker/workspace/iree.sh; \  
    elif [ "$SERVICE_NAME" = "base" ]; then \  
      echo "Running no additional setup for base"; \  
    else \  
      echo "No specific setup for $SERVICE_NAME"; \  
    fi  

