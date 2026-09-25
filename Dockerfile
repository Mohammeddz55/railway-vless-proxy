FROM alpine:3.19

RUN apk add --no-cache \
    curl unzip ca-certificates bash tzdata jq caddy

ARG XRAY_VERSION=1.8.24

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "$ARCH" in \
        x86_64)  XRAY_ARCH="64" ;; \
        aarch64) XRAY_ARCH="arm64-v8a" ;; \
        *)       XRAY_ARCH="64" ;; \
    esac; \
    curl -fL --retry 5 -o /tmp/xray.zip \
      "https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip"; \
    unzip -o /tmp/xray.zip -d /usr/local/bin/; \
    chmod +x /usr/local/bin/xray; \
    rm -f /tmp/xray.zip

WORKDIR /app
COPY config.json /app/config.json
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/app/start.sh"]
