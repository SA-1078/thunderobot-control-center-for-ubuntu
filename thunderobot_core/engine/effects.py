import math
from abc import ABC, abstractmethod

def cosine_ease(frac: float) -> float:
    """
    Standard harmonic cosine interpolation (identical to Morph Dual).
    Decelerates smoothly to 0 velocity at the boundaries, providing an
    organic, non-forced, silky-smooth transition.
    """
    return (1.0 - math.cos(frac * math.pi)) / 2.0

def interpolate_rgb(c1: tuple | list, c2: tuple | list, blend: float) -> tuple[int, int, int]:
    """Blends two RGB colors linearly using the harmonic ease factor."""
    r = int(c1[0] * (1.0 - blend) + c2[0] * blend)
    g = int(c1[1] * (1.0 - blend) + c2[1] * blend)
    b = int(c1[2] * (1.0 - blend) + c2[2] * blend)
    return max(2, r), max(2, g), max(2, b)


class BaseEffect(ABC):
    def __init__(self, name: str):
        self.name = name

    @abstractmethod
    def next_frame(self, t: float, speed: float, color: list, secondary_color: list, ctx: dict) -> tuple[int, int, int]:
        """Returns (r, g, b) values in 0-255 range."""
        pass


class RainbowEffect(BaseEffect):
    """
    Seamless multi-stage harmonic color morph across the full spectrum ring.
    Uses the exact same harmonic cosine blend as Morph Dual between each curated waypoint.
    """
    def __init__(self):
        super().__init__("rainbow")
        self.phase = 0.0
        # Curated harmonic color palette (rich aesthetic tones, zero harsh jumps)
        self.palette = [
            (0, 229, 255),   # Cyan Cyber
            (0, 102, 255),   # Electric Blue
            (112, 0, 255),   # Purple Pulse
            (255, 0, 128),   # Neon Pink / Magenta
            (255, 23, 68),   # Crimson Red
            (255, 153, 0),   # Amber Gold
            (0, 255, 136),   # Emerald / Toxic Green
        ]

    def next_frame(self, t: float, speed: float, color: list, secondary_color: list, ctx: dict) -> tuple[int, int, int]:
        # Smooth progression matching Morph Dual speed
        self.phase += 0.04 * speed
        total = len(self.palette)

        idx = int(self.phase) % total
        next_idx = (idx + 1) % total
        frac = self.phase - math.floor(self.phase)

        # Same harmonic cosine easing as Morph Dual
        blend = cosine_ease(frac)
        return interpolate_rgb(self.palette[idx], self.palette[next_idx], blend)


class BreathingEffect(BaseEffect):
    """
    Organic respiratory breathing curve with harmonic cosine easing and dual-color morphing.
    Smoothly inhales in Primary Color, exhales, and inhales in Secondary Color (if defined),
    or breathes gracefully in a single color with zero harshness.
    """
    def __init__(self):
        super().__init__("breathing")
        self.phase = 0.0

    def next_frame(self, t: float, speed: float, color: list, secondary_color: list, ctx: dict) -> tuple[int, int, int]:
        # Silky calm breathing pace matching Morph Dual
        self.phase += 0.045 * speed

        # Harmonic respiratory curve (intensity modulation)
        # Cosine ease guarantees zero acceleration at peaks and troughs
        breath_ease = (1.0 - math.cos(self.phase)) / 2.0
        intensity = 0.05 + 0.95 * breath_ease  # Safe 5% floor prevents EC 0x000000

        # Harmonious color morph across breath cycles
        # Inhale 1 -> Primary Color; Inhale 2 -> Secondary Color
        color_ease = (1.0 - math.cos(self.phase / 2.0)) / 2.0
        r_base, g_base, b_base = interpolate_rgb(color, secondary_color, color_ease)

        r = max(2, int(r_base * intensity))
        g = max(2, int(g_base * intensity))
        b = max(2, int(b_base * intensity))
        return r, g, b


class ColorMorphEffect(BaseEffect):
    """
    The reference harmonic morph: fluid cosine cross-fade between 2 chosen colors.
    """
    def __init__(self):
        super().__init__("color_cycle")
        self.phase = 0.0

    def next_frame(self, t: float, speed: float, color: list, secondary_color: list, ctx: dict) -> tuple[int, int, int]:
        self.phase += 0.045 * speed
        blend = (1.0 - math.cos(self.phase)) / 2.0
        return interpolate_rgb(color, secondary_color, blend)


class ThermalReactiveEffect(BaseEffect):
    """
    Thermal reactive transition using harmonic cosine interpolation between
    cool cyan, warm amber, and hot crimson.
    """
    def __init__(self):
        super().__init__("cpu_temp")
        self.cool_color = (0, 229, 255)   # Cyan Cyber
        self.mid_color  = (255, 153, 0)   # Amber Gold
        self.hot_color  = (255, 23, 68)   # Crimson Red

    def next_frame(self, t: float, speed: float, color: list, secondary_color: list, ctx: dict) -> tuple[int, int, int]:
        cpu_t = ctx.get("cpu_temp", 50.0)
        # Range: 45C (Cool) to 85C (Hot)
        clamped = max(45.0, min(85.0, float(cpu_t)))
        norm = (clamped - 45.0) / 40.0  # 0.0 to 1.0

        if norm < 0.5:
            # Morph from Cool -> Mid (45C - 65C)
            sub_ratio = norm * 2.0
            blend = cosine_ease(sub_ratio)
            return interpolate_rgb(self.cool_color, self.mid_color, blend)
        else:
            # Morph from Mid -> Hot (65C - 85C)
            sub_ratio = (norm - 0.5) * 2.0
            blend = cosine_ease(sub_ratio)
            return interpolate_rgb(self.mid_color, self.hot_color, blend)


class StaticEffect(BaseEffect):
    def __init__(self):
        super().__init__("static")

    def next_frame(self, t: float, speed: float, color: list, secondary_color: list, ctx: dict) -> tuple[int, int, int]:
        return max(2, int(color[0])), max(2, int(color[1])), max(2, int(color[2]))
