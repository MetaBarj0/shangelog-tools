FROM alpine:latest as base
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update

FROM base as dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add bash git

FROM dependencies as dev_dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add pcre-tools

FROM dev_dependencies as prepare_volume
RUN mkdir -p /root/ringover-shangelog-tools
VOLUME /root/ringover-shangelog-tools
WORKDIR /root/ringover-shangelog-tools

FROM prepare_volume as setup_entrypoint
COPY scripts /root
ENTRYPOINT /root/entrypoint.sh
