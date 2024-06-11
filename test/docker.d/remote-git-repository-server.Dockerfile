FROM alpine:edge AS base
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk update

FROM base AS dependencies
RUN \
  --mount=type=cache,target=/var/cache/apk \
  apk add man-db git git-doc openssh openssh-doc shadow

FROM dependencies AS create_git_user
RUN adduser -h /home/git -D git
# otherwise account is locked and cannot ssh into it
RUN usermod -p '*' git
WORKDIR /home/git
USER git
RUN mkdir .ssh
USER root

FROM create_git_user AS setup_entrypoint
USER root
COPY scripts/remote-git-repository-server-entrypoint.sh /home/git
COPY \
  --chown=git:git \
  --chmod=0555 \
  scripts/create-bare-repository-in.sh /home/git
ENTRYPOINT ["/home/git/remote-git-repository-server-entrypoint.sh"]
