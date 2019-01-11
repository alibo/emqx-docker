FROM erlang:21.2-alpine

MAINTAINER Huang Rui <vowstar@gmail.com>, EMQ X Team <support@emqx.io>

ENV EMQX_VERSION=v3.0.0
ENV HOME /opt/emqx
ENV TZ=UTC

RUN set -xe \
        && apk add --no-cache --virtual .fetch-deps \
        build-base \
        curl \
        bsd-compat-headers \
        ca-certificates \
        && apk add --no-cache --virtual .build-deps \
        tar \
        git \
        wget \
        make \
        gcc \
        bsd-compat-headers \
        perl \
        libc-dev \
        autoconf \
        linux-headers \
        dpkg-dev dpkg \
        ncurses-dev \
        openssl-dev \
        coreutils \
        lksctp-tools-dev \
        && apk add --virtual .erlang-rundeps $runDeps lksctp-tools \
        && cd / && git clone -b ${EMQX_VERSION} https://github.com/emqx/emqx-rel /emqx \
        && cd /emqx \
        && curl -fSL -o erlang.mk https://raw.githubusercontent.com/emqx/erlmk/master/erlang.mk \
        && make \
        && mkdir -p /opt/emqx && mv /emqx/_rel/emqx/* /opt/emqx/ \
        && cd / && rm -rf /emqx \
        && ln -s /opt/emqx/bin/* /usr/local/bin/ \
        && apk --purge del .build-deps .fetch-deps \
        && rm -rf /var/cache/apk/* 

WORKDIR ${HOME}

COPY ./start.sh ./
RUN chmod +x ./start.sh

RUN mkdir -p /opt/emqx/log /opt/emqx/data /opt/emqx/lib /opt/emqx/etc \
        && chgrp -R 0 /opt/emqx \
        && chmod -R g=u /opt/emqx \
        && chmod g=u /etc/passwd

# VOLUME ["/opt/emqx/log", "/opt/emqx/data", "/opt/emqx/lib", "/opt/emqx/etc"]

# emqx will occupy these port:
# - 1883 port for MQTT
# - 8883 port for MQTT(SSL)
# - 8083 for WebSocket/HTTP
# - 8084 for WSS/HTTPS
# - 8080 for mgmt API
# - 18083 for dashboard
# - 4369 for port mapping
# - 5369 for gen_rpc port mapping
# - 6369 for distributed node
EXPOSE 1883 8883 8083 8084 8080 18083 4369 5369 6369 6000-6999

RUN apk add --no-cache curl

RUN echo 'export EMQ_CLUSTER__K8S__APP_NAME=`hostname`' >> /etc/profile

# start emqx and initial environments
CMD ["./start.sh"]
