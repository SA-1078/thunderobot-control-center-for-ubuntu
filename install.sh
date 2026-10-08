#!/usr/bin/env bash
# ==============================================================================
# Thunderobot Control Center for Ubuntu / Linux - Universal Installer
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
    echo "Por favor ejecuta este script con bash: bash install.sh o ./install.sh"
    exit 1
fi

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[ERROR] Por favor NO ejecutes este instalador con "sudo" o como root.${NC}"
    echo -e "Ejecútalo como tu usuario habitual: ${BOLD}./install.sh${NC}"
    echo -e "El script solicitará permisos de sudo únicamente cuando sea necesario para las reglas de hardware."
    exit 1
fi

echo -e "${CYAN}${BOLD}"
echo "  ========================================================"
echo "    THUNDEROBOT CONTROL CENTER - INSTALADOR PARA UBUNTU"
echo "  ========================================================"
echo -e "${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/thunderobot-control-center"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

# 1. Verificar dependencias básicas
echo -e "${YELLOW}[1/6] Verificando dependencias del sistema...${NC}"
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}[ERROR] Python 3 no está instalado. Instálalo con: sudo apt install python3${NC}"
    exit 1
fi

if ! python3 -c "import psutil" 2>/dev/null; then
    echo -e "${YELLOW}[*] Instalando python3-psutil necesario para telemetría...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y -qq python3-psutil || pip3 install --user psutil
fi
echo -e "${GREEN}✓ Dependencias de Python verificadas.${NC}"

# 2. Compilar o verificar paquete de Flutter
echo -e "${YELLOW}[2/6] Preparando la interfaz gráfica (Flutter)...${NC}"
RELEASE_BUNDLE="$SCRIPT_DIR/thunderobot_app/build/linux/x64/release/bundle"

# Detectar Flutter si existe en el sistema
FLUTTER_CMD=""
if command -v flutter &>/dev/null; then
    FLUTTER_CMD="flutter"
elif [ -f "/opt/flutter/bin/flutter" ]; then
    FLUTTER_CMD="/opt/flutter/bin/flutter"
fi

REBUILD=false
if [ "$1" = "--rebuild" ] || [ "$1" = "-b" ]; then
    REBUILD=true
fi

if [ -f "$RELEASE_BUNDLE/thunderobot_app" ] && [ "$REBUILD" = "false" ]; then
    echo -e "${GREEN}✓ Utilizando binario release previamente compilado.${NC}"
    echo -e "  (Usa './install.sh --rebuild' si realizaste cambios en el código Flutter)"
elif [ -n "$FLUTTER_CMD" ]; then
    echo -e "${CYAN}[*] Compilando versión de producción con Flutter (${FLUTTER_CMD})...${NC}"
    (cd "$SCRIPT_DIR/thunderobot_app" && "$FLUTTER_CMD" pub get && "$FLUTTER_CMD" build linux --release)
elif [ ! -f "$RELEASE_BUNDLE/thunderobot_app" ]; then
    echo -e "${RED}[ERROR] No se encontró el binario compilado ni Flutter SDK instalado.${NC}"
    echo -e "Para compilar desde el código fuente se requiere Flutter."
    echo -e "Instálalo o ejecuta: cd thunderobot_app && flutter build linux --release"
    exit 1
else
    echo -e "${GREEN}✓ Utilizando binario release existente.${NC}"
fi

# 3. Detener servicio previo para actualizar de forma segura (evita Text file busy)
echo -e "${YELLOW}[3/6] Preparando instalación limpia en $INSTALL_DIR...${NC}"
if systemctl --user is-active --quiet thunderobot.service 2>/dev/null; then
    echo -e "${CYAN}[*] Deteniendo servicio en ejecución temporalmente para actualizar archivos...${NC}"
    systemctl --user stop thunderobot.service || true
fi

if pgrep -x thunderobot_app &>/dev/null; then
    echo -e "${YELLOW}[*] Cerrando interfaz en ejecución...${NC}"
    pkill -x thunderobot_app 2>/dev/null || true
    sleep 1
fi

mkdir -p "$INSTALL_DIR/assets"
mkdir -p "$BIN_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$SYSTEMD_USER_DIR"

# Limpiar subcarpetas previas para una instalación 100% limpia
rm -rf "$INSTALL_DIR/app" "$INSTALL_DIR/daemon"
mkdir -p "$INSTALL_DIR/app"
mkdir -p "$INSTALL_DIR/daemon"

# Copiar aplicación binaria
cp -r "$RELEASE_BUNDLE"/* "$INSTALL_DIR/app/"
chmod +x "$INSTALL_DIR/app/thunderobot_app" 2>/dev/null || true

# Copiar demonio del motor
cp -r "$SCRIPT_DIR/thunderobot_core" "$INSTALL_DIR/daemon/"
cp "$SCRIPT_DIR/thunderobot_controller.py" "$INSTALL_DIR/daemon/"
chmod +x "$INSTALL_DIR/daemon/thunderobot_controller.py" 2>/dev/null || true

# Limpiar posibles __pycache__ viejos
find "$INSTALL_DIR/daemon" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Copiar icono de la aplicación
cp "$SCRIPT_DIR/thunderobot_app/assets/thunderobot.png" "$INSTALL_DIR/assets/thunderobot.png"

# 4. Crear lanzador universal en ~/.local/bin
echo -e "${YELLOW}[4/6] Configurando lanzador del sistema...${NC}"
cat << 'BIN_EOF' > "$BIN_DIR/thunderobot-control-center"
#!/usr/bin/env bash
# Asegurar que el demonio en segundo plano está activo
if ! systemctl --user is-active --quiet thunderobot.service; then
    systemctl --user start thunderobot.service 2>/dev/null || true
fi
exec "$HOME/.local/share/thunderobot-control-center/app/thunderobot_app" "$@"
BIN_EOF
chmod +x "$BIN_DIR/thunderobot-control-center"

# 5. Instalar acceso directo en el escritorio y menú de aplicaciones
echo -e "${YELLOW}[5/6] Creando acceso directo (.desktop)...${NC}"
cat << DESK_EOF > "$DESKTOP_DIR/thunderobot-control-center.desktop"
[Desktop Entry]
Name=Thunderobot Control Center
Comment=Centro de Control Nativo para Laptop Thunderobot RS (Linux)
Exec=$BIN_DIR/thunderobot-control-center
Icon=$INSTALL_DIR/assets/thunderobot.png
Terminal=false
Type=Application
Categories=Settings;HardwareSettings;System;
Keywords=thunderobot;control;center;rgb;keyboard;fan;thermal;performance;
StartupNotify=true
StartupWMClass=thunderobot_app
DESK_EOF
chmod +x "$DESKTOP_DIR/thunderobot-control-center.desktop"
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

# 6. Configurar y activar servicio systemd de usuario
echo -e "${YELLOW}[6/6] Configurando servicio en segundo plano (systemd user)...${NC}"
cat << 'SVC_EOF' > "$SYSTEMD_USER_DIR/thunderobot.service"
[Unit]
Description=Thunderobot RS Control Center Daemon
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=%h/.local/share/thunderobot-control-center/daemon
ExecStart=/usr/bin/python3 %h/.local/share/thunderobot-control-center/daemon/thunderobot_controller.py
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
SVC_EOF

systemctl --user daemon-reload
systemctl --user enable thunderobot.service
systemctl --user restart thunderobot.service

# Verificar estado del servicio
sleep 1
if systemctl --user is-active --quiet thunderobot.service; then
    echo -e "${GREEN}✓ Servicio en segundo plano activo y respondiendo.${NC}"
else
    echo -e "${YELLOW}[!] Advertencia: El servicio aún no reporta estado activo.${NC}"
    echo -e "    Inspecciona con: journalctl --user -u thunderobot.service -n 20"
fi

# 7. Permisos de hardware (udev)
if [ ! -f "/etc/udev/rules.d/99-thunderobot.rules" ]; then
    echo -e "${CYAN}[*] Configurando reglas de hardware (udev) para RGB y ventiladores...${NC}"
    if [ -f "$SCRIPT_DIR/setup_permissions.sh" ]; then
        sudo bash "$SCRIPT_DIR/setup_permissions.sh" || true
    fi
else
    echo -e "${GREEN}✓ Reglas de hardware udev ya configuradas.${NC}"
fi

echo -e "\n${GREEN}${BOLD}========================================================${NC}"
echo -e "${GREEN}${BOLD}  ¡INSTALACIÓN COMPLETADA CON ÉXITO!                     ${NC}"
echo -e "${GREEN}${BOLD}========================================================${NC}"
echo -e "Puedes abrir la aplicación desde:"
echo -e " 1. Menú de Aplicaciones de Ubuntu: ${BOLD}Thunderobot Control Center${NC}"
echo -e " 2. En tu terminal ejecutando:      ${BOLD}thunderobot-control-center${NC}"
echo -e " 3. El servicio del motor corre automáticamente en: ${BOLD}systemctl --user status thunderobot.service${NC}"
echo -e "\n${CYAN}Para desinstalar de forma 100% limpia ejecuta: ./uninstall.sh${NC}\n"
