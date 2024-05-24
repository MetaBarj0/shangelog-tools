FROM alpine:latest as base
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update

FROM base as dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add man-db git git-doc openssh openssh-doc shadow

FROM dependencies as create_git_user
RUN adduser -h /home/git -D git
# otherwise account is locked and cannot ssh into it
RUN usermod -p '*' git
WORKDIR /home/git
USER git
RUN mkdir .ssh
USER root

FROM create_git_user as setup_entrypoint
COPY scripts/remote-git-repository-server-entrypoint.sh /root
COPY \
  --chown=git:git \
  scripts/create-bare-repository-in.sh /home/git
ENTRYPOINT ["/root/remote-git-repository-server-entrypoint.sh"]
