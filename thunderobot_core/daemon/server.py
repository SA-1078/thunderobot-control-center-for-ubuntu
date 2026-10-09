import json
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from thunderobot_core.hal.ec_led import ECLedInterface
from thunderobot_core.hal.thermal import ThermalSensorManager
from thunderobot_core.engine.scheduler import AnimationScheduler
from thunderobot_core.daemon.config import ConfigManager

class ThunderobotDaemon:
    def __init__(self):
        self.config_mgr = ConfigManager()
        self.led_hal = ECLedInterface()
        self.thermal_hal = ThermalSensorManager()
        self.scheduler = AnimationScheduler(
            self.led_hal,
            get_context_cb=self._get_context
        )
        self.fan_boost = False
        self._init_from_config()

    def _get_context(self) -> dict:
        return {
            "cpu_temp": self.thermal_hal.get_cpu_temp(),
            "gpu_temp": self.thermal_hal.get_gpu_temp(),
        }

    def _init_from_config(self):
        cfg = self.config_mgr.load()
        self.led_hal.write_brightness(cfg.get("brightness", 4))
        self.thermal_hal.set_power_profile(cfg.get("power_profile", "balanced"))
        self.fan_boost = cfg.get("fan_boost", False)
        self.scheduler.set_effect(
            cfg.get("effect", "rainbow"),
            cfg.get("speed", 1.0),
            cfg.get("color", [0, 255, 236]),
            cfg.get("secondary_color", [255, 0, 128])
        )

    def get_status(self) -> dict:
        return {
            "effect": self.scheduler.current_effect_name,
            "speed": self.scheduler.speed,
            "color": self.scheduler.color,
            "secondary_color": self.scheduler.secondary_color,
            "brightness": self.led_hal.get_hw_brightness(),
            "power_profile": self.thermal_hal.get_power_profile(),
            "fn_lock": self.thermal_hal.get_fn_lock(),
            "fan_boost": self.fan_boost,
            "fan_speeds": self.thermal_hal.get_fan_speeds(),
            "cpu_temp": self.thermal_hal.get_cpu_temp(),
            "gpu_temp": self.thermal_hal.get_gpu_temp(),
        }

    def save_state(self):
        self.config_mgr.save(self.get_status())


daemon_instance = ThunderobotDaemon()


class RestRequestHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send_json(self, data: dict, code: int = 200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Connection", "close")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Connection", "close")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in ["/status", "/api/status"]:
            self._send_json(daemon_instance.get_status())
        else:
            self._send_json({"error": "Not Found"}, 404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8") if length > 0 else "{}"
        try:
            req = json.loads(body) if body else {}
        except Exception:
            self._send_json({"error": "Invalid JSON"}, 400)
            return

        if parsed.path in ["/effect", "/api/effect"]:
            effect = req.get("effect", daemon_instance.scheduler.current_effect_name)
            speed = float(req.get("speed", daemon_instance.scheduler.speed))
            color = req.get("color", daemon_instance.scheduler.color)
            secondary = req.get("secondary_color", daemon_instance.scheduler.secondary_color)
            daemon_instance.scheduler.set_effect(effect, speed, color, secondary)
            daemon_instance.save_state()
            self._send_json({"status": "ok", "current": daemon_instance.get_status()})

        elif parsed.path in ["/brightness", "/api/brightness"]:
            level = int(req.get("brightness", daemon_instance.led_hal.get_hw_brightness()))
            daemon_instance.led_hal.write_brightness(level)
            daemon_instance.save_state()
            self._send_json({"status": "ok", "brightness": level})

        elif parsed.path in ["/power", "/api/power"]:
            profile = req.get("profile", "balanced")
            success = daemon_instance.thermal_hal.set_power_profile(profile)
            daemon_instance.save_state()
            self._send_json({"status": "ok" if success else "failed", "power_profile": profile})

        elif parsed.path in ["/stop", "/api/stop"]:
            daemon_instance.scheduler.set_effect("off")
            self._send_json({"status": "ok", "effect": "off"})

        elif parsed.path in ["/fn_lock", "/api/fn_lock"]:
            enabled = bool(req.get("enabled", False))
            success = daemon_instance.thermal_hal.set_fn_lock(enabled)
            daemon_instance.save_state()
            self._send_json({"status": "ok" if success else "failed", "fn_lock": enabled})

        elif parsed.path in ["/fan_boost", "/api/fan_boost"]:
            enabled = bool(req.get("enabled", False))
            daemon_instance.fan_boost = enabled
            success = daemon_instance.thermal_hal.set_fan_boost(enabled)
            daemon_instance.save_state()
            self._send_json({
                "status": "ok" if success else "failed",
                "fan_boost": enabled,
                "fan_speeds": daemon_instance.thermal_hal.get_fan_speeds()
            })

        elif parsed.path in ["/fan_speed", "/api/fan_speed"]:
            fan_index = int(req.get("fan_index", 0))
            percent = int(req.get("percent", 50))
            success = daemon_instance.thermal_hal.set_fan_speed(fan_index, percent)
            self._send_json({"status": "ok" if success else "failed", "fan_index": fan_index, "percent": percent})

        else:
            self._send_json({"error": "Unknown Endpoint"}, 404)

    def log_message(self, format, *args):
        pass


class ReusableThreadingServer(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def serve(port: int = 18888):
    server = ReusableThreadingServer(("127.0.0.1", port), RestRequestHandler)
    print(f"[*] Thunderobot Suite Daemon running on http://127.0.0.1:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping daemon...")
        daemon_instance.scheduler.stop_worker()
