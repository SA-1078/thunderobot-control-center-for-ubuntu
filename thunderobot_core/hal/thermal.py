import os
import glob
import subprocess
import fcntl
import struct
import threading
import time

SYSFS_FN_LOCK = "/sys/devices/platform/tuxedo_keyboard/fn_lock"
DEV_TUXEDO_IO = "/dev/tuxedo_io"

IOCTL_R_UW_FANSPEED = 0x8008ef10
IOCTL_R_UW_FANSPEED2 = 0x8008ef11
IOCTL_W_UW_FANSPEED = 0x4008f010
IOCTL_W_UW_FANSPEED2 = 0x4008f011
IOCTL_W_UW_FANAUTO = 0xf014
IOCTL_W_UW_PERF_PROF = 0x4008f018

class ThermalSensorManager:
    def __init__(self):
        self._cpu_temp_path = self._find_cpu_temp_path()
        self._fan_boost = False
        self._cached_fan_speeds = {"cpu_fan_pct": 28, "gpu_fan_pct": 28, "available": True}

    def _find_cpu_temp_path(self) -> str:
        # Look for k10temp (AMD Ryzen)
        for h in glob.glob("/sys/class/hwmon/hwmon*"):
            name_file = os.path.join(h, "name")
            if os.path.exists(name_file):
                try:
                    with open(name_file, "r") as f:
                        if "k10temp" in f.read():
                            temp_input = os.path.join(h, "temp1_input")
                            if os.path.exists(temp_input):
                                return temp_input
                except Exception:
                    pass
        # Fallback to any valid temp1_input
        for h in glob.glob("/sys/class/hwmon/hwmon*"):
            temp_input = os.path.join(h, "temp1_input")
            if os.path.exists(temp_input):
                return temp_input
        return ""

    def get_cpu_temp(self) -> float:
        if not self._cpu_temp_path or not os.path.exists(self._cpu_temp_path):
            self._cpu_temp_path = self._find_cpu_temp_path()

        if self._cpu_temp_path and os.path.exists(self._cpu_temp_path):
            try:
                with open(self._cpu_temp_path, "r") as f:
                    return round(int(f.read().strip()) / 1000.0, 1)
            except Exception:
                pass
        return 0.0

    def get_gpu_temp(self) -> float:
        try:
            out = subprocess.check_output(
                ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader"],
                timeout=1
            ).decode().strip()
            return float(out)
        except Exception:
            return 0.0

    def get_fn_lock(self) -> bool:
        try:
            if os.path.exists(SYSFS_FN_LOCK):
                with open(SYSFS_FN_LOCK, "r") as f:
                    return f.read().strip() == "1"
        except Exception:
            pass
        return False

    def set_fn_lock(self, enable: bool) -> bool:
        try:
            with open(SYSFS_FN_LOCK, "w") as f:
                f.write("1\n" if enable else "0\n")
            return True
        except Exception:
            return False

    def set_power_profile(self, profile: str) -> bool:
        mapping = {
            "office": ("power-saver", 1),
            "office mode": ("power-saver", 1),
            "quiet": ("power-saver", 1),
            "power-saver": ("power-saver", 1),
            "balanced": ("balanced", 2),
            "performance": ("performance", 3),
            "performance mode": ("performance", 3),
        }
        entry = mapping.get(str(profile).lower())
        if not entry:
            return False
        os_target, ec_target = entry
        try:
            subprocess.run(["powerprofilesctl", "set", os_target], check=True, timeout=2)
        except Exception:
            pass

        if os.path.exists(DEV_TUXEDO_IO):
            try:
                fd = os.open(DEV_TUXEDO_IO, os.O_RDWR | os.O_NONBLOCK)
                try:
                    buf = struct.pack("i", ec_target) + b"\x00\x00\x00\x00"
                    fcntl.ioctl(fd, IOCTL_W_UW_PERF_PROF, buf)
                finally:
                    os.close(fd)
            except Exception as e:
                print(f"[!] Error setting EC performance profile: {e}")

        return True

    def get_power_profile(self) -> str:
        try:
            out = subprocess.check_output(["powerprofilesctl", "get"], timeout=2).decode().strip()
            return out
        except Exception:
            return "balanced"

    def set_fan_boost(self, enable: bool) -> bool:
        if not os.path.exists(DEV_TUXEDO_IO):
            if enable:
                self.set_power_profile("performance")
            else:
                self.set_power_profile("balanced")
            return False
        try:
            fd = os.open(DEV_TUXEDO_IO, os.O_RDWR | os.O_NONBLOCK)
            try:
                if enable:
                    # 200 is NB02_FAN_SPEED_MAX (100% full fan blast)
                    speed_max = 200
                    buf = struct.pack("i", speed_max) + b"\x00\x00\x00\x00"
                    # Fan 0 (CPU)
                    fcntl.ioctl(fd, IOCTL_W_UW_FANSPEED, buf)
                    # Fan 1 (GPU)
                    fcntl.ioctl(fd, IOCTL_W_UW_FANSPEED2, buf)
                    self.set_power_profile("performance")
                else:
                    # Restore automatic hardware fan curve
                    fcntl.ioctl(fd, IOCTL_W_UW_FANAUTO, 0)
                    self.set_power_profile("balanced")
                return True
            finally:
                os.close(fd)
        except Exception as e:
            print(f"[!] Error controlling fans via {DEV_TUXEDO_IO}: {e}")
            if enable:
                self.set_power_profile("performance")
            else:
                self.set_power_profile("balanced")
            return False

    def get_fan_speeds(self) -> dict:
        if self._fan_boost:
            return {"cpu_fan_pct": 100, "gpu_fan_pct": 100, "available": True}
        return dict(self._cached_fan_speeds)

    def set_fan_speed(self, fan_index: int, percent: int) -> bool:
        if not os.path.exists(DEV_TUXEDO_IO):
            return False
        target_val = int((max(0, min(100, percent)) / 100.0) * 200)
        ioctl_cmd = IOCTL_W_UW_FANSPEED if fan_index == 0 else IOCTL_W_UW_FANSPEED2
        try:
            fd = os.open(DEV_TUXEDO_IO, os.O_RDWR)
            try:
                buf = struct.pack("i", target_val) + b"\x00\x00\x00\x00"
                fcntl.ioctl(fd, ioctl_cmd, buf)
                return True
            finally:
                os.close(fd)
        except Exception as e:
            print(f"[!] Error setting fan {fan_index} to {percent}%: {e}")
            return False

