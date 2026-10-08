import os
import subprocess
import threading
import time

SYSFS_CHARGING_PATH = "/sys/devices/platform/tuxedo_keyboard/charging_profile/charging_profile"
SYSFS_BATTERY_DIR = "/sys/class/power_supply/BAT0"


class BatteryManager:
    PROFILE_MAP = {
        "60": "stationary",
        60: "stationary",
        "stationary": "stationary",
        "80": "balanced",
        80: "balanced",
        "balanced": "balanced",
        "100": "high_capacity",
        100: "high_capacity",
        "high_capacity": "high_capacity",
    }

    THRESHOLD_MAP = {
        "stationary": 60,
        "balanced": 80,
        "high_capacity": 100,
    }

    def __init__(self, charging_path: str = SYSFS_CHARGING_PATH, battery_dir: str = SYSFS_BATTERY_DIR):
        self.charging_path = charging_path
        self.battery_dir = battery_dir
        self.current_profile = "high_capacity"
        self.assisted_alert_enabled = True
        self.last_alert_time = 0.0
        self.alert_cooldown = 300.0  # Remind every 5 minutes if still plugged in
        self.already_alerted_session = False

        # Load current profile from sysfs if possible
        prof = self.get_profile()
        if prof in self.PROFILE_MAP:
            self.current_profile = prof

        # Start background monitor thread for alerts
        self._running = True
        self._monitor_thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self._monitor_thread.start()

    def set_profile(self, target: str) -> bool:
        # PURE READ-ONLY: Never write to sysfs or interfere with physical charging
        self.current_profile = "high_capacity"
        self.already_alerted_session = False
        return True

    def get_profile(self) -> str:
        try:
            if os.path.exists(self.charging_path):
                with open(self.charging_path, "r") as f:
                    val = f.read().strip()
                    if val in self.PROFILE_MAP:
                        return val
        except Exception:
            pass
        return self.current_profile

    def get_target_threshold(self) -> int:
        return self.THRESHOLD_MAP.get(self.current_profile, 100)

    def trigger_test_alert(self) -> bool:
        """Trigger an instant notification and sound to test system compatibility."""
        return self._send_notification(
            title="⚡ Thunderobot Control Center",
            message="🔔 Prueba de Alerta Inteligente: ¡Notificaciones y audio funcionando correctamente!",
            urgency="normal"
        )

    def _send_notification(self, title: str, message: str, urgency: str = "critical") -> bool:
        try:
            # 1. Desktop Notification
            cmd = [
                "notify-send",
                "-u", urgency,
                "-i", "battery-full-charging",
                title,
                message
            ]
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # 2. Audio Chime (if sound file exists)
            for sound in [
                "/usr/share/sounds/freedesktop/stereo/complete.oga",
                "/usr/share/sounds/freedesktop/stereo/dialog-information.oga",
                "/usr/share/sounds/freedesktop/stereo/bell.oga"
            ]:
                if os.path.exists(sound):
                    subprocess.Popen(
                        ["paplay", sound],
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL
                    )
                    break
            return True
        except Exception as e:
            print(f"[BatteryManager] Error sending notification: {e}")
            return False

    def _monitor_loop(self):
        while self._running:
            try:
                telemetry = self.get_telemetry()
                status = telemetry.get("status", "Unknown")
                capacity = telemetry.get("capacity", 0)
                threshold = self.get_target_threshold()

                if status == "Charging":
                    if threshold < 100 and capacity >= threshold:
                        now = time.time()
                        should_alert = False
                        if not self.already_alerted_session:
                            should_alert = True
                            self.already_alerted_session = True
                            self.last_alert_time = now
                        elif (now - self.last_alert_time) >= self.alert_cooldown:
                            should_alert = True
                            self.last_alert_time = now

                        if should_alert and self.assisted_alert_enabled:
                            mode_name = "Gaming (60%)" if threshold == 60 else "Equilibrado (80%)"
                            self._send_notification(
                                title="🔋 Thunderobot: Límite de Batería Alcanzado",
                                message=(
                                    f"La batería ha alcanzado el {capacity}% (Modo {mode_name}).\n"
                                    "Desconecta el cargador para evitar estrés químico y proteger la vida útil."
                                ),
                                urgency="critical"
                            )
                else:
                    # User unplugged or battery is discharging
                    self.already_alerted_session = False
            except Exception as e:
                pass
            time.sleep(4)

    def get_telemetry(self) -> dict:
        info = {
            "capacity": 0,
            "status": "Unknown",
            "profile": self.current_profile,
            "threshold": self.get_target_threshold(),
            "hardware_limiting_supported": False,
            "assisted_alert_enabled": self.assisted_alert_enabled,
            "voltage_v": 0.0,
            "current_a": 0.0,
            "power_w": 0.0,
        }
        try:
            cap_p = os.path.join(self.battery_dir, "capacity")
            stat_p = os.path.join(self.battery_dir, "status")
            volt_p = os.path.join(self.battery_dir, "voltage_now")
            curr_p = os.path.join(self.battery_dir, "current_now")

            if os.path.exists(cap_p):
                with open(cap_p, "r") as f:
                    info["capacity"] = int(f.read().strip())
            if os.path.exists(stat_p):
                with open(stat_p, "r") as f:
                    info["status"] = f.read().strip()
            if os.path.exists(volt_p):
                with open(volt_p, "r") as f:
                    info["voltage_v"] = round(int(f.read().strip()) / 1_000_000.0, 2)
            if os.path.exists(curr_p):
                with open(curr_p, "r") as f:
                    info["current_a"] = round(int(f.read().strip()) / 1_000_000.0, 2)

            info["power_w"] = round(info["voltage_v"] * info["current_a"], 2)
        except Exception:
            pass
        return info

