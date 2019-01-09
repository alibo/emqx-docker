FROM erlang:21.2-alpine

MAINTAINER Huang Rui <vowstar@gmail.com>, EMQ X Team <support@emqx.io>

ENV EMQX_VERSION=emqx30
ENV EMQX_DEPS_DEFAULT_VSN=${EMQX_VERSION}
ENV HOME /opt/emqx

RUN set -xe \
        && apk add --no-cache --virtual .fetch-deps \
        curl \
        bsd-compat-headers \
        ca-certificates \
        && apk add --no-cache --virtual .build-deps \
        tar \
        git \
        wget \
        && apk add --virtual .erlang-rundeps $runDeps lksctp-tools \
        && cd / && git clone -b ${EMQX_VERSION} https://github.com/emqx/emqx-rel /emqx \
        && cd /emqx \
        && make \
        && mkdir -p /opt && mv /emqx/_rel/emqx /opt/emqx \
        && cd / && rm -rf /emqx \
        && ln -s /opt/emqx/bin/* /usr/local/bin/ \
        && apk --purge del .build-deps .fetch-deps \
        && rm -rf /var/cache/apk/* \

        WORKDIR ${HOME}

COPY ./start.sh ./
RUN chmod +x ./start.sh

RUN adduser -D -u 10001 emqx
RUN chgrp -Rf emqx /opt/emqx && chmod -Rf g+w /opt/emqx \
        && chown -Rf emqx /opt/emqx

USER 10001

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

# start emqx and initial environments
CMD ["./start.sh"]
