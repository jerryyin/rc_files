# Base image
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Reset ENTRYPOINT from any base image so docker-compose command works correctly
# (e.g., triton-mi450.dockerfile uses shell-form ENTRYPOINT which ignores CMD)
ENTRYPOINT []

USER root
WORKDIR /root

RUN printf 'Acquire::http::proxy "%s";\nAcquire::https::proxy "%s";\n' "${HTTP_PROXY:-}" "${HTTPS_PROXY:-}" > /etc/apt/apt.conf

WORKDIR /root

ARG SERVICE_NAME
RUN apt-get update && apt-get -y install wget && \
    wget -qO /tmp/setup-service.sh https://raw.githubusercontent.com/jerryyin/scripts/master/docker/setup-service.sh && \
    bash /tmp/setup-service.sh "$SERVICE_NAME"

