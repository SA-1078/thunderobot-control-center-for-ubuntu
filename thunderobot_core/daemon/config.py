import os
import json

CONFIG_DIR = os.path.expanduser("~/.config/thunderobot")
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.json")

DEFAULT_CONFIG = {
    "effect": "rainbow",
    "speed": 1.0,
    "color": [0, 255, 236],
    "secondary_color": [255, 0, 128],
    "brightness": 4,
    "charging_profile": "high_capacity",
    "power_profile": "balanced"
}

class ConfigManager:
    def __init__(self, path: str = CONFIG_PATH):
        self.path = path
        os.makedirs(os.path.dirname(self.path), exist_ok=True)

    def load(self) -> dict:
        if os.path.exists(self.path):
            try:
                with open(self.path, "r") as f:
                    data = json.load(f)
                    cfg = DEFAULT_CONFIG.copy()
                    cfg.update(data)
                    return cfg
            except Exception:
                pass
        return DEFAULT_CONFIG.copy()

    def save(self, data: dict):
        try:
            with open(self.path, "w") as f:
                json.dump(data, f, indent=2)
        except Exception:
            pass
