import os
import threading

SYSFS_LED_DIR = "/sys/class/leds/rgb:kbd_backlight"

class ECLedInterface:
    def __init__(self, led_dir: str = SYSFS_LED_DIR):
        self.multi_intensity_path = os.path.join(led_dir, "multi_intensity")
        self.brightness_path = os.path.join(led_dir, "brightness")
        self._last_rgb = None
        self._lock = threading.Lock()

    def get_hw_brightness(self) -> int:
        """Reads the physical brightness set by the keyboard Fn keys or software (0-4)."""
        try:
            with open(self.brightness_path, "r") as f:
                return max(0, min(4, int(f.read().strip())))
        except Exception:
            return 4

    def write_brightness(self, level: int):
        """Sets the hardware brightness level (0-4)."""
        level = max(0, min(4, int(level)))
        with self._lock:
            try:
                with open(self.brightness_path, "w") as f:
                    f.write(f"{level}\n")
                print(f"[OK] Brillo hardware establecido a {level}/4")
            except Exception as e:
                print(f"[ERR] Error escribiendo brillo: {e}")

    def write_color(self, r: int, g: int, b: int, force: bool = False):
        """
        Writes RGB values to multi_intensity scaled by the physical Fn brightness level.
        Respects Fn Off state (brightness == 0).
        """
        hw_b = self.get_hw_brightness()

        # If user turned off keyboard via physical Fn key or app, do NOT write color
        if hw_b == 0:
            return

        # Scale RGB according to the physical Fn key level (1=25%, 2=50%, 3=75%, 4=100%)
        scale = hw_b / 4.0
        r = int(r * scale)
        g = int(g * scale)
        b = int(b * scale)

        r = max(0, min(255, r))
        g = max(0, min(255, g))
        b = max(0, min(255, b))

        # Hardware safety guard: prevent EC 0x000000 demo mode
        if r == 0 and g == 0 and b == 0:
            r, g, b = 2, 2, 2

        with self._lock:
            if not force and self._last_rgb == (r, g, b):
                return
            self._last_rgb = (r, g, b)

            try:
                with open(self.multi_intensity_path, "w") as f:
                    f.write(f"{r} {g} {b}\n")
            except Exception:
                pass
