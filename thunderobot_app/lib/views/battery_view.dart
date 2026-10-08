import 'package:flutter/material.dart';
import '../services/i18n_service.dart';

class BatteryView extends StatelessWidget {
  final Map<String, dynamic> status;

  const BatteryView({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bat = status['battery'] ?? {};
    final int capacity = bat['capacity'] ?? 0;
    final String chargeStatus = bat['status'] ?? 'Unknown';
    final double voltage = (bat['voltage_v'] as num?)?.toDouble() ?? 0.0;
    final double current = (bat['current_a'] as num?)?.toDouble() ?? 0.0;
    final double power = (bat['power_w'] as num?)?.toDouble() ?? 0.0;

    final bool isCharging = chargeStatus == 'Charging';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.tr('battery_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            I18n.tr('battery_subtitle'),
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // Safety assurance banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF00FF88), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        I18n.tr('safe_mode_notice_title'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        I18n.tr('safe_mode_notice_desc'),
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Battery Level Hero Box
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF13161F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222736)),
            ),
            child: Row(
              children: [
                // Big Circular Indicator
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (capacity / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFF1B1F2C),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          capacity > 20 ? const Color(0xFF00FF88) : const Color(0xFFFF3366),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$capacity%',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCharging ? Icons.power : Icons.battery_charging_full,
                            color: isCharging ? const Color(0xFF00FF88) : Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCharging ? I18n.tr('charger_connected') : I18n.tr('on_battery'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isCharging ? const Color(0xFF00FF88) : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        I18n.tr('system_status', {'status': chargeStatus}),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isCharging
                          ? I18n.tr('charging_desc')
                          : I18n.tr('discharging_desc'),
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Telemetry Grid
          Text(
            I18n.tr('sensors_header'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white54),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _telemetryTile(
                  title: I18n.tr('power_metric'),
                  value: '${power.toStringAsFixed(1)} W',
                  icon: Icons.electric_meter_outlined,
                  color: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _telemetryTile(
                  title: I18n.tr('voltage_metric'),
                  value: '${voltage.toStringAsFixed(2)} V',
                  icon: Icons.speed_outlined,
                  color: const Color(0xFFFF9900),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _telemetryTile(
                  title: I18n.tr('current_metric'),
                  value: '${(current * 1000).toStringAsFixed(0)} mA',
                  icon: Icons.compress_outlined,
                  color: const Color(0xFF00FF88),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _telemetryTile({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
