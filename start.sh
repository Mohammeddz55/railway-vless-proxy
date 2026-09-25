#!/bin/bash
set -euo pipefail

# ============================================================
#  start.sh — Caddy + Xray
# ============================================================
PORT="${PORT:-8080}"
XRAY_PORT="${XRAY_INTERNAL_PORT:-8081}"

echo "=============================================="
echo "  Railway VLESS Proxy"
echo "  Public port (Caddy): ${PORT}"
echo "  Internal port (Xray): ${XRAY_PORT}"
echo "=============================================="

# ---- Build Caddyfile ----
cat > /app/Caddyfile <<EOF
{
    admin off
    auto_https off
    log {
        output stdout
        format console
        level INFO
    }
}

:${PORT} {
    # Health check endpoint for Railway
    handle /health {
        respond "OK" 200
    }

    # WebSocket endpoint → forward to Xray
    handle /ws* {
        reverse_proxy 127.0.0.1:${XRAY_PORT} {
            header_up Host {host}
        }
    }

    # Root — return a friendly response (not used by clients)
    handle / {
        respond "Railway VLESS Proxy — OK" 200
    }

    # Everything else → forward to Xray (fallback)
    handle {
        reverse_proxy 127.0.0.1:${XRAY_PORT}
    }
}
EOF

echo "[start.sh] Caddyfile:"
cat /app/Caddyfile

# ---- Generate Xray config (in case UUID is overridden) ----
if [[ -n "${UUID:-}" ]]; then
    jq --arg uuid "$UUID" \
       --argjson port "$XRAY_PORT" \
       '.inbounds[0].settings.clients[0].id = $uuid | .inbounds[0].port = $port' \
       /app/config.json > /tmp/config.json
    mv /tmp/config.json /app/config.json
fi

echo "[start.sh] Xray config:"
cat /app/config.json

# ---- Cleanup on exit ----
cleanup() {
    echo "[start.sh] Shutting down..."
    [[ -n "${XRAY_PID:-}" ]] && kill "$XRAY_PID" 2>/dev/null || true
    [[ -n "${CADDY_PID:-}" ]] && kill "$CADDY_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ---- Start Xray ----
echo "[start.sh] Starting Xray..."
/usr/local/bin/xray run -c /app/config.json &
XRAY_PID=$!

sleep 2

# ---- Start Caddy ----
echo "[start.sh] Starting Caddy..."
caddy run --config /app/Caddyfile --adapter caddyfile &
CADDY_PID=$!

# ---- Keep container running; restart everything if either dies ----
while true; do
    if ! kill -0 "$XRAY_PID" 2>/dev/null; then
        echo "[start.sh] Xray died. Restarting..."
        /usr/local/bin/xray run -c /app/config.json &
        XRAY_PID=$!
    fi
    if ! kill -0 "$CADDY_PID" 2>/dev/null; then
        echo "[start.sh] Caddy died. Restarting..."
        caddy run --config /app/Caddyfile --adapter caddyfile &
        CADDY_PID=$!
    fi
    sleep 5
done
