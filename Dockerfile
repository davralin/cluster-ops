FROM debian:stable-slim
LABEL MAINTAINER davralin

RUN \
  /usr/bin/apt-get -y update && \
  /usr/bin/apt-get -y install --no-install-recommends \
    adb \
    fastboot \
    heimdall-flash \
    && \
    /bin/rm -rf /var/lib/apt/lists/*

ENTRYPOINT    ["sh", "-c"]
CMD           ["trap : TERM INT; sleep infinity & wait"]
