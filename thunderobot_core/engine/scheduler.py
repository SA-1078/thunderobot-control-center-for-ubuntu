import time
import threading
from typing import Optional
from thunderobot_core.hal.ec_led import ECLedInterface
from thunderobot_core.engine.effects import (
    BaseEffect,
    RainbowEffect,
    BreathingEffect,
    ColorMorphEffect,
    ThermalReactiveEffect,
    StaticEffect
)

class AnimationScheduler:
    def __init__(self, hal_led: ECLedInterface, get_context_cb=None):
        self.hal_led = hal_led
        self.get_context_cb = get_context_cb
        self.effects: dict[str, BaseEffect] = {
            "rainbow": RainbowEffect(),
            "breathing": BreathingEffect(),
            "color_cycle": ColorMorphEffect(),
            "cpu_temp": ThermalReactiveEffect(),
            "static": StaticEffect(),
        }

        # Thread-safe atomic state
        self._lock = threading.Lock()
        self.current_effect_name = "rainbow"
        self.speed = 1.0
        self.color = [0, 255, 236]
        self.secondary_color = [255, 0, 128]
        self.is_active = True

        self._t = 0.0
        self.stop_event = threading.Event()
        self.wake_event = threading.Event()

        # Single persistent background worker thread - NEVER duplicate or stack threads
        self.worker = threading.Thread(target=self._worker_loop, daemon=True, name="RGB_Worker")
        self.worker.start()

    def set_effect(self, effect_name: str, speed: float = 1.0, color=None, secondary_color=None):
        """Atomically replaces the active effect, discarding previous state immediately."""
        with self._lock:
            if effect_name == "off":
                self.is_active = False
                self.hal_led.write_brightness(0)
                self.wake_event.set()
                return

            self.is_active = True
            if self.hal_led.get_hw_brightness() == 0:
                self.hal_led.write_brightness(4)

            if effect_name not in self.effects:
                effect_name = "rainbow"

            self.current_effect_name = effect_name
            self.speed = max(0.1, min(10.0, float(speed)))
            if color:
                self.color = [int(c) for c in color]
            if secondary_color:
                self.secondary_color = [int(c) for c in secondary_color]

            # Reset animation clock on change
            self._t = 0.0

            # If static color, apply immediately
            if self.current_effect_name == "static":
                self.hal_led.write_color(self.color[0], self.color[1], self.color[2], force=True)

            print(f"[ENGINE] Nuevo efecto configurado: {self.current_effect_name} (Vel: {self.speed}x, Color: {self.color})")

        # Wake the worker immediately from sleep
        self.wake_event.set()

    def stop_worker(self):
        self.stop_event.set()
        self.wake_event.set()
        if self.worker.is_alive():
            self.worker.join(timeout=0.4)

    def _worker_loop(self):
        """Single consumer loop: guarantees exactly one effect is processed at any given moment."""
        while not self.stop_event.is_set():
            self.wake_event.clear()

            with self._lock:
                active = self.is_active
                effect_name = self.current_effect_name
                speed = self.speed
                color = list(self.color)
                sec_color = list(self.secondary_color)

            # Check hardware brightness (physical Fn keys)
            hw_b = self.hal_led.get_hw_brightness()
            if not active or hw_b == 0:
                # If keyboard is turned off by Fn keys or app, sleep quietly
                self.wake_event.wait(timeout=0.3)
                continue

            if effect_name == "static":
                # Static mode: color is already written; sleep until user changes something
                self.wake_event.wait(timeout=0.5)
                continue

            effect = self.effects.get(effect_name, self.effects["rainbow"])
            ctx = self.get_context_cb() if self.get_context_cb else {}

            self._t += 0.05
            r, g, b = effect.next_frame(self._t, speed, color, sec_color, ctx)
            self.hal_led.write_color(r, g, b)

            # Frame pacing: ~12 FPS keeps the EC bus completely responsive without backlog
            sleep_interval = 0.4 if effect_name == "cpu_temp" else 0.08
            self.wake_event.wait(timeout=sleep_interval)
