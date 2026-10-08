#!/usr/bin/env python3
import sys
import os
import shutil
import subprocess

SRC_DIR = "/usr/src/tuxedo-drivers-4.22.3"

if os.geteuid() != 0:
    print("ERROR: This script must be run as root (sudo)!")
    sys.exit(1)

print("[1/6] Patching tuxedo_compatibility_check.c...")
compat_file = os.path.join(SRC_DIR, "tuxedo_compatibility_check/tuxedo_compatibility_check.c")
if not os.path.exists(compat_file + ".orig"):
    shutil.copy2(compat_file, compat_file + ".orig")

with open(compat_file, "r") as f:
    compat_code = f.read()

old_compat_fn = """bool tuxedo_is_compatible(void) {
	if (dmi_check_system(tuxedo_dmi_string_match)
	    || (x86_match_cpu(skip_tuxedo_dmi_string_check_match)
	    && !x86_match_cpu(force_tuxedo_dmi_string_check_match))) {
		return true;
	}
	return false;
}"""

new_compat_fn = """bool tuxedo_is_compatible(void) {
	// Patched for THUNDEROBOT support
	return true;
}"""

if old_compat_fn in compat_code:
    compat_code = compat_code.replace(old_compat_fn, new_compat_fn)
    with open(compat_file, "w") as f:
        f.write(compat_code)
    print("  -> tuxedo_compatibility_check.c patched successfully.")
else:
    import re
    compat_code = re.sub(
        r"bool tuxedo_is_compatible\(void\)\s*\{[^}]+\}",
        "bool tuxedo_is_compatible(void) {\n\treturn true;\n}",
        compat_code
    )
    with open(compat_file, "w") as f:
        f.write(compat_code)
    print("  -> tuxedo_compatibility_check.c ensured return true.")

print("[2/6] Patching tuxedo_keyboard.c to completely bypass check...")
tk_file = os.path.join(SRC_DIR, "tuxedo_keyboard.c")
if not os.path.exists(tk_file + ".orig"):
    shutil.copy2(tk_file, tk_file + ".orig")

with open(tk_file, "r") as f:
    tk_code = f.read()

old_tk_init = """static int __init tuxedo_keyboard_init(void)
{
	TUXEDO_INFO("module init\\n");

	if (!tuxedo_is_compatible())
		return -ENODEV;

	return 0;
}"""

new_tk_init = """static int __init tuxedo_keyboard_init(void)
{
	TUXEDO_INFO("module init (patched for THUNDEROBOT)\\n");
	return 0;
}"""

if old_tk_init in tk_code:
    tk_code = tk_code.replace(old_tk_init, new_tk_init)
    with open(tk_file, "w") as f:
        f.write(tk_code)
    print("  -> tuxedo_keyboard.c patched successfully.")
elif "patched for THUNDEROBOT" in tk_code:
    print("  -> tuxedo_keyboard.c already patched.")
else:
    import re
    tk_code = re.sub(
        r"static int __init tuxedo_keyboard_init\(void\)\s*\{[^}]+\}",
        "static int __init tuxedo_keyboard_init(void)\n{\n\tTUXEDO_INFO(\"module init (patched for THUNDEROBOT)\\n\");\n\treturn 0;\n}",
        tk_code
    )
    with open(tk_file, "w") as f:
        f.write(tk_code)
    print("  -> tuxedo_keyboard.c init replaced.")

print("[3/6] Patching uniwill_leds.h for RGB keyboard support...")
leds_file = os.path.join(SRC_DIR, "uniwill_leds.h")
if not os.path.exists(leds_file + ".orig"):
    shutil.copy2(leds_file, leds_file + ".orig")

with open(leds_file, "r") as f:
    leds_code = f.read()

target_leds = """	if (dmi_check_system(force_no_ec_led_control)) {
		pr_debug("Skip uniwill_kb_backlight_type checks because of quirk.\\n");
	}"""

replacement_leds = """	if (dmi_match(DMI_SYS_VENDOR, "THUNDEROBOT") || dmi_match(DMI_BOARD_NAME, "RS")) {
		pr_info("uniwill_leds: THUNDEROBOT RS detected, enabling 1_ZONE_RGB\\n");
		uniwill_kb_backlight_type = UNIWILL_KB_BACKLIGHT_TYPE_1_ZONE_RGB;
		uniwill_kbl_brightness_ec_controlled = true;
	}
	else if (dmi_check_system(force_no_ec_led_control)) {
		pr_debug("Skip uniwill_kb_backlight_type checks because of quirk.\\n");
	}"""

if target_leds in leds_code:
    leds_code = leds_code.replace(target_leds, replacement_leds)
    with open(leds_file, "w") as f:
        f.write(leds_code)
    print("  -> uniwill_leds.h patched successfully.")
elif "THUNDEROBOT RS detected" in leds_code:
    print("  -> uniwill_leds.h already patched.")
else:
    print("  -> Note: uniwill_leds.h already configured.")

print("[4/6] Patching uniwill_keyboard.h for power profiles...")
kbd_file = os.path.join(SRC_DIR, "uniwill_keyboard.h")
if not os.path.exists(kbd_file + ".orig"):
    shutil.copy2(kbd_file, kbd_file + ".orig")

with open(kbd_file, "r") as f:
    kbd_code = f.read()

target_prof = """	uw_feats->uniwill_profile_v1_three_profs = false
	// Devices with "classic" profile support
		|| dmi_match(DMI_BOARD_NAME, "POLARIS1501A1650TI")"""

replacement_prof = """	uw_feats->uniwill_profile_v1_three_profs = false
	// Devices with "classic" profile support
		|| dmi_match(DMI_SYS_VENDOR, "THUNDEROBOT")
		|| dmi_match(DMI_BOARD_NAME, "RS")
		|| dmi_match(DMI_BOARD_NAME, "POLARIS1501A1650TI")"""

target_custom = """	uw_feats->uniwill_custom_profile_mode_needed = false
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 18, 0)
		|| dmi_match(DMI_PRODUCT_SKU, "STELLARIS16I06")"""

replacement_custom = """	uw_feats->uniwill_custom_profile_mode_needed = false
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4, 18, 0)
		|| dmi_match(DMI_SYS_VENDOR, "THUNDEROBOT")
		|| dmi_match(DMI_BOARD_NAME, "RS")
		|| dmi_match(DMI_PRODUCT_SKU, "STELLARIS16I06")"""

if target_prof in kbd_code:
    kbd_code = kbd_code.replace(target_prof, replacement_prof)
if target_custom in kbd_code:
    kbd_code = kbd_code.replace(target_custom, replacement_custom)

with open(kbd_file, "w") as f:
    f.write(kbd_code)
print("  -> uniwill_keyboard.h patched successfully.")

print("[5/6] Unloading old kernel modules from RAM...")
old_mods = [
    "tuxedo_keyboard",
    "uniwill_wmi",
    "tuxedo_compatibility_check",
    "uniwill-laptop"
]
for m in old_mods:
    subprocess.run(f"rmmod {m} 2>/dev/null || true", shell=True)

print("[6/6] Rebuilding and installing via DKMS...")
kernel_ver = subprocess.check_output(["uname", "-r"]).decode().strip()
print(f"  Target kernel: {kernel_ver}")

cmds = [
    "dkms remove tuxedo-drivers/4.22.3 --all || true",
    f"dkms build tuxedo-drivers/4.22.3 -k {kernel_ver}",
    f"dkms install tuxedo-drivers/4.22.3 -k {kernel_ver} --force",
]

for cmd in cmds:
    print(f"  Running: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

print("Loading kernel modules...")
modules = ["tuxedo_keyboard", "uniwill_wmi"]
for mod in modules:
    print(f"  Loading {mod}...")
    subprocess.run(["modprobe", mod], check=True)

print("Restarting tccd daemon...")
subprocess.run(["systemctl", "restart", "tccd"])
print("\n=== SUCCESS! All modules loaded and patched successfully ===")
