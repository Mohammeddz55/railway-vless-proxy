# ============================================================
#  Railway VLESS Proxy — Caddy + Xray
# ============================================================
FROM alpine:3.19

# ---- Install runtime dependencies ----
RUN apk add --no-cache \
    curl \
    unzip \
    ca-certificates \
    bash \
    tzdata \
    jq \
    caddy

# ---- Download Xray-core ----
ARG XRAY_VERSION=1.8.24
ARG XRAY_FALLBACK_VERSION=1.8.23

RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "$ARCH" in \
        x86_64)  XRAY_ARCH="64" ;; \
        aarch64) XRAY_ARCH="arm64-v8a" ;; \
        *)       XRAY_ARCH="64" ;; \
    esac; \
    URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${XRAY_ARCH}.zip"; \
    FALLBACK_URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_FALLBACK_VERSION}/Xray-linux-${XRAY_ARCH}.zip"; \
    if ! curl -fL --retry 5 --retry-delay 3 --connect-timeout 30 -o /tmp/xray.zip "$URL"; then \
        echo "Fallback to ${XRAY_FALLBACK_VERSION}"; \
        curl -fL --retry 5 --retry-delay 3 --connect-timeout 30 -o /tmp/xray.zip "$FALLBACK_URL"; \
    fi; \
    unzip -o /tmp/xray.zip -d /usr/local/bin/; \
    chmod +x /usr/local/bin/xray; \
    rm -f /tmp/xray.zip; \
    /usr/local/bin/xray version || true

# ---- App directory ----
WORKDIR /app

# ---- Copy files ----
COPY config.json /app/config.json
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# ---- Defaults (can be overridden in Railway Variables) ----
ENV UUID="944b54e0-e81b-4fa9-bc26-65b81d3ed393" \
    XRAY_INTERNAL_PORT=8081 \
    XRAY_LOG_LEVEL="warning"

# Railway injects PORT; fallback 8080
ENV PORT=8080

# ---- Expose public port ----
EXPOSE 8080

# ---- Entrypoint ----
ENTRYPOINT ["/app/start.sh"]
