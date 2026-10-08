#!/usr/bin/env bash
# ==============================================================================
# Thunderobot Control Center - Uninstaller Script
# ==============================================================================
set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
NC="\033[0m"

# Control de ejecución
if [ -z "$BASH_VERSION" ]; then
    echo "Por favor ejecuta este script con bash: bash uninstall.sh o ./uninstall.sh"
    exit 1
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ERROR] Por favor NO ejecutes este desinstalador con "sudo" o como root.${NC}"
    echo -e "Ejecútalo como tu usuario habitual: ${BOLD}./uninstall.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}${BOLD}"
echo "  ========================================================"
echo "    THUNDEROBOT CONTROL CENTER - DESINSTALADOR"
echo "  ========================================================"
echo -e "${NC}"

# 1. Cerrar procesos activos de la interfaz
echo "[*] Cerrando interfaz de usuario si está abierta..."
pkill -x thunderobot_app 2>/dev/null || true

# 2. Detener y deshabilitar servicio systemd del usuario
echo "[*] Deteniendo y deshabilitando servicio en segundo plano..."
if systemctl --user is-active --quiet thunderobot.service 2>/dev/null; then
    systemctl --user stop thunderobot.service || true
fi
systemctl --user disable thunderobot.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/thunderobot.service"
systemctl --user daemon-reload 2>/dev/null || true
pkill -f thunderobot_controller.py 2>/dev/null || true

# 3. Eliminar accesos directos y ejecutables del sistema
echo "[*] Eliminando accesos directos y ejecutables..."
rm -f "$HOME/.local/share/applications/thunderobot-control-center.desktop"
rm -f "$HOME/.local/bin/thunderobot-control-center"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# 4. Eliminar archivos de la aplicación instalada
echo "[*] Eliminando archivos de ~/.local/share/thunderobot-control-center/..."
rm -rf "$HOME/.local/share/thunderobot-control-center"

# 5. Opcional: Eliminar archivos de preferencias y perfiles del usuario
if [ -d "$HOME/.config/thunderobot" ]; then
    rm_cfg="n"
    read -r -p "¿Deseas eliminar también las preferencias y perfiles guardados (~/.config/thunderobot)? (s/N): " rm_cfg || rm_cfg="n"
    if [[ "$rm_cfg" =~ ^[sS]$ ]]; then
        rm -rf "$HOME/.config/thunderobot"
        echo -e "${GREEN}[*] Configuración y perfiles de usuario eliminados.${NC}"
    else
        echo -e "${CYAN}[*] Configuración conservada para futuras instalaciones.${NC}"
    fi
fi

# 6. Opcional: Reglas de hardware (udev)
if [ -f "/etc/udev/rules.d/99-thunderobot.rules" ]; then
    rm_udev="n"
    read -r -p "¿Deseas eliminar las reglas udev de permisos de hardware? (s/N): " rm_udev || rm_udev="n"
    if [[ "$rm_udev" =~ ^[sS]$ ]]; then
        sudo rm -f /etc/udev/rules.d/99-thunderobot.rules
        sudo udevadm control --reload-rules && sudo udevadm trigger || true
        echo -e "${GREEN}[*] Reglas udev eliminadas.${NC}"
    fi
fi

echo -e "\n${GREEN}${BOLD}✓ Thunderobot Control Center ha sido desinstalado completamente de tu sistema.${NC}\n"
