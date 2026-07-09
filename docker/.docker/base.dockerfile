# Base image
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# Reset ENTRYPOINT from any base image so docker-compose command works correctly.
ENTRYPOINT []

USER root
WORKDIR /root

RUN printf 'Acquire::http::proxy "%s";\nAcquire::https::proxy "%s";\n' "${HTTP_PROXY:-}" "${HTTPS_PROXY:-}" > /etc/apt/apt.conf

WORKDIR /root

ARG SERVICE_NAME
# Clone scripts.git first so setup-service.sh can run from its canonical
# location with no self-bootstrap dance. min.sh's own `if [ ! -d scripts ]`
# check makes its clone block a no-op here.
RUN apt-get update && apt-get -y install git ca-certificates sudo wget curl gpg lsb-release && \
    git clone --depth 1 https://github.com/jerryyin/scripts.git /root/scripts && \
    git -C /root/scripts remote set-url origin git@github.com:jerryyin/scripts.git && \
    bash /root/scripts/docker/setup-service.sh "$SERVICE_NAME"
