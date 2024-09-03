# Tools image
FROM jeryin/tools:latest as tools

# Base image
FROM rocm/mlir:latest

WORKDIR /root

# Copy the prebuilt tools from the tools image
COPY --from=tools /usr/local /usr/local

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf
RUN git clone https://github.com/jerryyin/scripts.git

# lightweight setup script
RUN bash scripts/docker/init.sh
