FROM alpine:edge AS base
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update

FROM base AS dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add man-db bash bash-doc git git-doc pcre-tools pcre-doc tig tig-doc \
  parallel parallel-doc entr entr-doc docker-cli docker-cli-buildx docker-doc \
  rsync rsync-doc openssh-client openssh-doc expect expect-doc

FROM dependencies AS prepare_volume
RUN mkdir -p /root/ringover-shangelog-tools
VOLUME /root/ringover-shangelog-tools
WORKDIR /root/ringover-shangelog-tools

FROM prepare_volume AS setup_entrypoint
USER root
COPY scripts/tester-entrypoint.sh /root
COPY scripts/watch-and-run-test-suites-in-parallel.sh /root
ENTRYPOINT ["/root/tester-entrypoint.sh"]
