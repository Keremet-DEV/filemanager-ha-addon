ARG BUILD_FROM=ghcr.io/keremet-dev/filemanager-server:0.1.0
# hadolint ignore=DL3006
FROM $BUILD_FROM

# The server image runs as uid 65532; Home Assistant's /data and /share belong to root, so
# run.sh starts as root, prepares the directories and drops to 65532 with su-exec.
USER root
# hadolint ignore=DL3018
RUN apk add --no-cache jq curl su-exec
COPY run.sh /run.sh
RUN chmod 755 /run.sh
ENTRYPOINT ["/run.sh"]
