import 'package:flutter/material.dart';
import '../services/i18n_service.dart';

class SystemMonitorView extends StatelessWidget {
  final Map<String, dynamic> status;

  const SystemMonitorView({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cpuTemp = status['cpu_temp'] ?? 0.0;
    final gpuTemp = status['gpu_temp'] ?? 0.0;

    final fanSpeeds = status['fan_speeds'] as Map<String, dynamic>?;
    final int cpuFan = fanSpeeds?['cpu_fan_pct'] ?? ((status['fan_boost'] == true) ? 100 : 0);
    final int gpuFan = fanSpeeds?['gpu_fan_pct'] ?? ((status['fan_boost'] == true) ? 100 : 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.tr('sys_info_title'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            I18n.tr('sys_info_subtitle'),
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 24),

          // Hardware Specs Cards
          _buildHardwareCard(
            title: I18n.tr('cpu_info_title'),
            specs: I18n.tr('cpu_info_specs'),
            icon: Icons.memory,
            accentColor: const Color(0xFF00E5FF),
          ),
          const SizedBox(height: 14),
          _buildHardwareCard(
            title: I18n.tr('gpu_info_title'),
            specs: I18n.tr('gpu_info_specs'),
            icon: Icons.sports_esports,
            accentColor: const Color(0xFFFF007F),
          ),
          const SizedBox(height: 14),
          _buildHardwareCard(
            title: I18n.tr('memory_info_title'),
            specs: I18n.tr('memory_info_specs'),
            icon: Icons.developer_board,
            accentColor: const Color(0xFF00FF88),
          ),
          const SizedBox(height: 28),

          // Realtime Gauge Grid
          Text(
            I18n.tr('sys_monitor_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF13161F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF222736)),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildCircularMetric(
                  label: I18n.tr('metric_cpu_temp'),
                  value: '${cpuTemp.toStringAsFixed(0)}°C',
                  ratio: (cpuTemp / 100.0).clamp(0.0, 1.0),
                  color: const Color(0xFF00E5FF),
                  icon: Icons.thermostat,
                ),
                _buildCircularMetric(
                  label: I18n.tr('metric_gpu_temp'),
                  value: '${gpuTemp.toStringAsFixed(0)}°C',
                  ratio: (gpuTemp / 100.0).clamp(0.0, 1.0),
                  color: const Color(0xFFFF007F),
                  icon: Icons.speed,
                ),
                _buildCircularMetric(
                  label: I18n.tr('metric_cpu_fan'),
                  value: '$cpuFan%',
                  ratio: (cpuFan / 100.0).clamp(0.0, 1.0),
                  color: const Color(0xFF00E5FF),
                  icon: Icons.air,
                ),
                _buildCircularMetric(
                  label: I18n.tr('metric_gpu_fan'),
                  value: '$gpuFan%',
                  ratio: (gpuFan / 100.0).clamp(0.0, 1.0),
                  color: const Color(0xFFFF007F),
                  icon: Icons.air,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareCard({
    required String title,
    required String specs,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  specs,
                  style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularMetric({
    required String label,
    required String value,
    required double ratio,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: ratio,
                strokeWidth: 8,
                backgroundColor: const Color(0xFF1B1E29),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
        ),
      ],
    );
  }
}
