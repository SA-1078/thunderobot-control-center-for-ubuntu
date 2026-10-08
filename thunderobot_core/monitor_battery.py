import time
import os
import sys

BAT_DIR = "/sys/class/power_supply/BAT0"
PROFILE_PATH = "/sys/devices/platform/tuxedo_keyboard/charging_profile/charging_profile"

def read_file(path):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return ""

print("[*] Iniciando monitor de batería Thunderobot...")
last_status = ""
last_cap = -1
start_time = time.time()

# Run for up to 30 minutes or until state stabilizes
while time.time() - start_time < 1800:
    status = read_file(os.path.join(BAT_DIR, "status"))
    cap_str = read_file(os.path.join(BAT_DIR, "capacity"))
    current_str = read_file(os.path.join(BAT_DIR, "current_now"))
    voltage_str = read_file(os.path.join(BAT_DIR, "voltage_now"))
    profile = read_file(PROFILE_PATH)

    try:
        cap = int(cap_str)
    except ValueError:
        cap = -1

    try:
        current_ma = abs(int(current_str)) // 1000
    except ValueError:
        current_ma = 0

    try:
        voltage_v = round(int(voltage_str) / 1000000.0, 2)
    except ValueError:
        voltage_v = 0.0

    # Print on change or periodically
    if status != last_status or cap != last_cap or int(time.time() - start_time) % 30 == 0:
        t_str = time.strftime("%H:%M:%S")
        print(f"[{t_str}] Perfil: {profile} | Estado: {status} | Nivel: {cap}% | Corriente: {current_ma} mA | Voltaje: {voltage_v} V", flush=True)
        last_status = status
        last_cap = cap

    # Check threshold behavior around 60%
    if status == "Charging" and cap >= 60:
        if current_ma < 100 or status in ["Not charging", "Full"]:
            print(f"[!] EXITO: La batería alcanzó {cap}% y el flujo se ha detenido/limitado (Corriente: {current_ma} mA, Estado: {status})", flush=True)
            break
        elif cap >= 62:
            print(f"[!] ALERTA: La batería superó 60% y continúa cargando a {cap}% ({current_ma} mA).", flush=True)

    time.sleep(3)
