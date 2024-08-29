FROM rocm/mlir:latest

WORKDIR /root

RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf
RUN git clone https://github.com/jerryyin/scripts.git

RUN bash scripts/docker/init.sh
