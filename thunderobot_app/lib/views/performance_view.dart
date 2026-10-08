import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/i18n_service.dart';

class PerformanceView extends StatefulWidget {
  final ApiService api;
  final String powerProfile;
  final bool fnLock;
  final Map<String, dynamic> status;
  final Function(String profile) onPowerProfileChanged;
  final Function(bool enabled) onFnLockChanged;
  final Function(bool enabled) onFanBoostChanged;

  const PerformanceView({
    super.key,
    required this.api,
    required this.powerProfile,
    required this.fnLock,
    required this.status,
    required this.onPowerProfileChanged,
    required this.onFnLockChanged,
    required this.onFanBoostChanged,
  });

  @override
  State<PerformanceView> createState() => _PerformanceViewState();
}

class _PerformanceViewState extends State<PerformanceView> {
  String _selectedCustomProfile = 'Profile-1';
  bool _customModeActive = false;
  double _cpuFanSpeed = 50.0;
  double _gpuFanSpeed = 50.0;

  @override
  Widget build(BuildContext context) {
    final cpuTemp = widget.status['cpu_temp'] ?? 0.0;
    final gpuTemp = widget.status['gpu_temp'] ?? 0.0;
    final bool fanBoost = widget.status['fan_boost'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            I18n.tr('mode_selecting'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            I18n.tr('mode_subtitle'),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),

          // Live Temperature telemetry cards
          Row(
            children: [
              Expanded(
                child: _sensorCard(
                  title: I18n.tr('cpu_temp_title'),
                  value: '${cpuTemp}°C',
                  icon: Icons.memory,
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _sensorCard(
                  title: I18n.tr('gpu_temp_title'),
                  value: '${gpuTemp}°C',
                  icon: Icons.sports_esports,
                  color: const Color(0xFFFF007F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FAN BOOST HERO BANNER (Replicating Windows Fan Boost)
          _buildFanBoostBanner(fanBoost, widget.status),
          const SizedBox(height: 24),

          // 1. Office Mode Card
          _buildModeOption(
            keyName: 'power-saver',
            title: I18n.tr('office_mode_title'),
            description: I18n.tr('office_mode_desc'),
            icon: Icons.eco_outlined,
            accentColor: const Color(0xFF00FF88),
            active: !_customModeActive && (widget.powerProfile == 'power-saver' || widget.powerProfile == 'office'),
            onTap: () {
              setState(() => _customModeActive = false);
              widget.onPowerProfileChanged('power-saver');
            },
          ),
          const SizedBox(height: 14),

          // 2. Performance Mode Card
          _buildModeOption(
            keyName: 'performance',
            title: I18n.tr('perf_mode_title'),
            description: I18n.tr('perf_mode_desc'),
            icon: Icons.flash_on_outlined,
            accentColor: const Color(0xFF00E5FF),
            active: !_customModeActive && widget.powerProfile == 'performance',
            onTap: () {
              setState(() => _customModeActive = false);
              widget.onPowerProfileChanged('performance');
            },
          ),
          const SizedBox(height: 14),

          // 3. Balanced Mode Card
          _buildModeOption(
            keyName: 'balanced',
            title: I18n.tr('balanced_mode_title'),
            description: I18n.tr('balanced_mode_desc'),
            icon: Icons.balance_outlined,
            accentColor: const Color(0xFFFF9900),
            active: !_customModeActive && widget.powerProfile == 'balanced',
            onTap: () {
              setState(() => _customModeActive = false);
              widget.onPowerProfileChanged('balanced');
            },
          ),
          const SizedBox(height: 14),

          // 4. Custom Mode Setting (Exact match to Windows 203812.png)
          _buildCustomModeSection(),
          const SizedBox(height: 24),

          // Quick Switches (Fn Lock)
          _buildQuickSwitches(),
        ],
      ),
    );
  }

  Widget _buildFanBoostBanner(bool fanBoost, Map<String, dynamic> status) {
    final fanSpeeds = status['fan_speeds'] as Map<String, dynamic>?;
    final int cpuFan = fanSpeeds?['cpu_fan_pct'] ?? (fanBoost ? 100 : 0);
    final int gpuFan = fanSpeeds?['gpu_fan_pct'] ?? (fanBoost ? 100 : 0);
    final bool fansAvailable = fanSpeeds?['available'] ?? false;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: fanBoost ? const Color(0xFF00E5FF).withOpacity(0.12) : const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fanBoost ? const Color(0xFF00E5FF) : const Color(0xFF222736),
          width: fanBoost ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: fanBoost ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.air,
              color: fanBoost ? const Color(0xFF00E5FF) : Colors.white60,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      I18n.tr('fan_boost_title'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                         color: fanBoost ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fanBoost
                            ? I18n.tr('fan_boost_active')
                            : (fansAvailable
                                ? I18n.tr('fan_boost_ec_auto', {'cpu': '$cpuFan', 'gpu': '$gpuFan'})
                                : I18n.tr('fan_boost_auto')),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: fanBoost ? const Color(0xFF00E5FF) : Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  fansAvailable
                      ? I18n.tr('fan_telemetry_desc', {'cpu': '$cpuFan', 'gpu': '$gpuFan'})
                      : I18n.tr('fan_boost_desc'),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
          Switch(
            value: fanBoost,
            activeColor: const Color(0xFF00E5FF),
            activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: const Color(0xFF222736),
            onChanged: (val) {
              status['fan_boost'] = val;
              widget.onFanBoostChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomModeSection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _customModeActive ? const Color(0xFF7000FF).withOpacity(0.12) : const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _customModeActive ? const Color(0xFF7000FF) : const Color(0xFF222736),
          width: _customModeActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _customModeActive,
                activeColor: const Color(0xFF7000FF),
                onChanged: (val) {
                  setState(() => _customModeActive = val ?? false);
                  if (_customModeActive) {
                    widget.onPowerProfileChanged('performance');
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                I18n.tr('custom_mode_title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.tr('custom_mode_desc'),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Profile dropdown (Profile-1, Profile-2, Profile-3, Profile-4)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E3446)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCustomProfile,
                          dropdownColor: const Color(0xFF1B1F2C),
                          items: const [
                            DropdownMenuItem(value: 'Profile-1', child: Text('Profile-1', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Profile-2', child: Text('Profile-2', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Profile-3', child: Text('Profile-3', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Profile-4', child: Text('Profile-4', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCustomProfile = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Customize Button
                    ElevatedButton.icon(
                      onPressed: () => _showCustomizeFanDialog(context),
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(I18n.tr('customize_btn')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF222736),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // OK Button
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _customModeActive = true);
                        widget.onPowerProfileChanged('performance');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(I18n.tr('profile_applied', {'profile': _selectedCustomProfile})),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00E5FF),
                        side: const BorderSide(color: Color(0xFF00E5FF)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(I18n.tr('ok_btn')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomizeFanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF13161F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF222736)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 12),
                  Text(
                    I18n.tr('customize_dialog_title', {'profile': _selectedCustomProfile}),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.tr('customize_dialog_desc'),
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 24),
                    // CPU Fan Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(I18n.tr('cpu_fan_speed'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('${_cpuFanSpeed.toInt()}%', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _cpuFanSpeed,
                      min: 20,
                      max: 100,
                      divisions: 16,
                      activeColor: const Color(0xFF00E5FF),
                      inactiveColor: const Color(0xFF222736),
                      onChanged: (v) {
                        setDialogState(() => _cpuFanSpeed = v);
                        setState(() => _cpuFanSpeed = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    // GPU Fan Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(I18n.tr('gpu_fan_speed'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('${_gpuFanSpeed.toInt()}%', style: const TextStyle(color: Color(0xFFFF007F), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _gpuFanSpeed,
                      min: 20,
                      max: 100,
                      divisions: 16,
                      activeColor: const Color(0xFFFF007F),
                      inactiveColor: const Color(0xFF222736),
                      onChanged: (v) {
                        setDialogState(() => _gpuFanSpeed = v);
                        setState(() => _gpuFanSpeed = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(I18n.tr('cancel'), style: const TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _customModeActive = true);
                    widget.onPowerProfileChanged('performance');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(I18n.tr('save_profile')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sensorCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required String keyName,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: active ? accentColor.withOpacity(0.12) : const Color(0xFF13161F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? accentColor : const Color(0xFF222736),
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: active ? accentColor : Colors.transparent,
                  border: Border.all(
                    color: active ? accentColor : Colors.white38,
                    width: 2,
                  ),
                ),
                child: active
                    ? const Center(
                        child: Icon(Icons.check, size: 16, color: Colors.black),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: active ? accentColor : Colors.white70),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSwitches() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFF00E5FF), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.tr('fn_lock_title'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  I18n.tr('fn_lock_desc'),
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.fnLock,
            activeColor: const Color(0xFF00E5FF),
            activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: const Color(0xFF222736),
            onChanged: (val) => widget.onFnLockChanged(val),
          ),
        ],
      ),
    );
  }
}
