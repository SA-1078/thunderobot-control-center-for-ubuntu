#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure the systemd background daemon is active
if ! systemctl --user is-active --quiet thunderobot.service; then
    echo "[*] Iniciando servicio thunderobot.service..."
    systemctl --user start thunderobot.service 2>/dev/null || true
fi

PERM_BIN="$HOME/.local/share/thunderobot-control-center/app/thunderobot_app"
if [ -f "$PERM_BIN" ]; then
    echo "[*] Abriendo interfaz Thunderobot Control Center desde ~/.local/share/..."
    exec "$PERM_BIN" "$@"
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[*] Abriendo interfaz Thunderobot Control Center local..."
exec "$DIR/thunderobot_app/build/linux/x64/release/bundle/thunderobot_app" "$@"
