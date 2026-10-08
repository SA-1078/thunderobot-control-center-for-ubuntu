#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    echo "Por favor ejecuta este script con sudo: sudo $0"
    exit 1
fi

cat << 'EOF' > /etc/udev/rules.d/99-thunderobot.rules
SUBSYSTEM=="leds", KERNEL=="rgb:kbd_backlight", ACTION=="add|change", RUN+="/bin/chmod 0666 /sys/class/leds/rgb:kbd_backlight/multi_intensity /sys/class/leds/rgb:kbd_backlight/brightness"
SUBSYSTEM=="platform", KERNEL=="tuxedo_keyboard", ACTION=="add|change", RUN+="/bin/chmod 0666 /sys/devices/platform/tuxedo_keyboard/fn_lock"
KERNEL=="tuxedo_io", ACTION=="add|change", MODE="0666"
SUBSYSTEM=="tuxedo_io", ACTION=="add|change", MODE="0666"
EOF

udevadm control --reload-rules && udevadm trigger
chmod 0666 /sys/class/leds/rgb:kbd_backlight/multi_intensity /sys/class/leds/rgb:kbd_backlight/brightness 2>/dev/null || true
chmod 0666 /sys/devices/platform/tuxedo_keyboard/fn_lock 2>/dev/null || true
chmod 0666 /dev/tuxedo_io 2>/dev/null || true

echo "=== Reglas de permisos udev instaladas con éxito! ==="
