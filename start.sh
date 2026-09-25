#!/bin/bash
set -euo pipefail

PORT="${PORT:-8080}"
XRAY_PORT=8081

echo "=== Railway VLESS Proxy ==="
echo "Public: ${PORT}, Internal: ${XRAY_PORT}"

cat > /app/Caddyfile <<EOF
{
    admin off
    auto_https off
}

:${PORT} {
    handle /health {
        respond "OK" 200
    }
    handle {
        reverse_proxy 127.0.0.1:${XRAY_PORT}
    }
}
EOF

/usr/local/bin/xray run -c /app/config.json &
XRAY_PID=$!
sleep 2

caddy run --config /app/Caddyfile --adapter caddyfile &
CADDY_PID=$!

wait -n "$XRAY_PID" "$CADDY_PID" || true
exit 0
