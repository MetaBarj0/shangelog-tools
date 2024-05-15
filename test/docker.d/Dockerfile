FROM alpine:latest as base
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update

FROM base as dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add man-db bash bash-doc git git-doc pcre-tools pcre-doc tig tig-doc \
  parallel parallel-doc entr entr-doc docker docker-doc rsync rsync-doc

FROM dependencies as prepare_volume
VOLUME /root/ringover-shangelog-volume
RUN mkdir -p /root/ringover-shangelog-tools
VOLUME /root/ringover-shangelog-tools
WORKDIR /root/ringover-shangelog-tools

FROM prepare_volume as setup_entrypoint
COPY scripts /root
ENTRYPOINT ["/root/entrypoint.sh"]
