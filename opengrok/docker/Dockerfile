FROM bash:4.4

LABEL maintainer="uft.dev.ops@hpe.com" \
      version="1.0" \
      description="UFT source code update for opengrok"

ARG http_proxy=http://web-proxy.il.hpecorp.net:8080
ARG https_proxy=$http_proxy
ARG no_proxy=127.0.0.1,localhost

RUN apk --update add git openssh && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*


WORKDIR /apps
COPY ./src_update.sh ./src_update.sh

CMD ["bash", "src_update.sh"]