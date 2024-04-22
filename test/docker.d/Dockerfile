FROM alpine:latest
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update \
  && apk add bash git pcre-tools
COPY scripts /root
RUN mkdir -p /root/ringover-shangelog-tools
VOLUME /root/ringover-shangelog-tools
WORKDIR /root/ringover-shangelog-tools
ENTRYPOINT /root/entrypoint.sh
