import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/i18n_service.dart';
import 'views/lighting_view.dart';
import 'views/performance_view.dart';
import 'views/monitor_view.dart';
import 'views/battery_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18n.loadPreference();
  runApp(const ThunderobotApp());
}

class ThunderobotApp extends StatelessWidget {
  const ThunderobotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thunderobot Control Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF007F),
          surface: Color(0xFF171A24),
          error: Color(0xFFFF3366),
        ),
        fontFamily: 'Inter',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentTab = 0;
  final ApiService _api = ApiService();

  Timer? _pollTimer;
  Map<String, dynamic> _status = {};
  bool _connected = false;

  // Local effect parameters
  String _selectedEffect = 'rainbow';
  double _speed = 1.0;
  Color _primaryColor = const Color(0xFF00E5FF);
  Color _secondaryColor = const Color(0xFFFF007F);
  int _brightness = 4;
  bool _lightsEnabled = true;
  String _powerProfile = 'balanced';
  bool _fnLock = false;
  bool _initialSyncDone = false;
  int _consecutiveFailures = 0;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    I18n.localeNotifier.addListener(_onLocaleChanged);
    _startPolling();
    _ensureBackendRunning();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    I18n.localeNotifier.removeListener(_onLocaleChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _restartAndReconnect() async {
    if (_isReconnecting) return;
    setState(() => _isReconnecting = true);
    try {
      // 1. Try systemctl user restart first
      try {
        await Process.run('systemctl', ['--user', 'restart', 'thunderobot.service']);
      } catch (_) {}

      // 2. Also ensure script is running as fallback
      final scriptPath = File('../thunderobot_controller.py').existsSync()
          ? '../thunderobot_controller.py'
          : (File('thunderobot_controller.py').existsSync()
              ? 'thunderobot_controller.py'
              : '/home/santiago007/Descargas/ControlCenter_5.71.51.56_ThunderobotII_V6/thunderobot_controller.py');
      try {
        await Process.start('python3', [scriptPath], mode: ProcessStartMode.detached);
      } catch (_) {}

      // Wait a moment for server to bind
      await Future.delayed(const Duration(milliseconds: 600));

      final data = await _api.getStatus();
      if (mounted && data != null) {
        setState(() {
          _status = data;
          _connected = true;
          _consecutiveFailures = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isReconnecting = false);
      }
    }
  }

  void _ensureBackendRunning() async {
    bool online = await _api.ping();
    if (!online) {
      _restartAndReconnect();
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      final data = await _api.getStatus();
      if (mounted && data != null) {
        _consecutiveFailures = 0;
        setState(() {
          _status = data;
          _connected = true;
          _powerProfile = data['power_profile'] ?? _powerProfile;
          _fnLock = data['fn_lock'] ?? _fnLock;

          if (data['brightness'] != null) {
            _brightness = data['brightness'];
            _lightsEnabled = _brightness > 0;
          }

          if (!_initialSyncDone) {
            _initialSyncDone = true;
            _selectedEffect = data['effect'] ?? _selectedEffect;
            _speed = (data['speed'] as num?)?.toDouble() ?? _speed;

            if (data['color'] != null) {
              final c = data['color'];
              _primaryColor = Color.fromARGB(255, c[0], c[1], c[2]);
            }
            if (data['secondary_color'] != null) {
              final c = data['secondary_color'];
              _secondaryColor = Color.fromARGB(255, c[0], c[1], c[2]);
            }
          }
        });
      } else if (mounted && data == null) {
        _consecutiveFailures++;
        setState(() {
          _connected = false;
        });
        // Auto-recover automatically if disconnected for 2 consecutive polls
        if (_consecutiveFailures >= 2 && !_isReconnecting) {
          _restartAndReconnect();
        }
      }
    });
  }

  void _applyEffect(String effect, double speed, Color primary, Color secondary) {
    setState(() {
      _selectedEffect = effect;
      _speed = speed;
      _primaryColor = primary;
      _secondaryColor = secondary;
      _lightsEnabled = true;
    });
    _api.setEffect(
      effect: effect,
      speed: speed,
      r: primary.red,
      g: primary.green,
      b: primary.blue,
      secR: secondary.red,
      secG: secondary.green,
      secB: secondary.blue,
    );
  }

  void _toggleLights(bool enable) {
    setState(() => _lightsEnabled = enable);
    if (enable) {
      _applyEffect(_selectedEffect, _speed, _primaryColor, _secondaryColor);
    } else {
      _api.stop();
    }
  }

  void _updateBrightness(int level) {
    setState(() {
      _brightness = level;
      _lightsEnabled = level > 0;
    });
    _api.setBrightness(level);
  }

  void _updatePowerProfile(String profile) {
    setState(() {
      _powerProfile = profile;
      _status['power_profile'] = profile;
    });
    _api.setPowerProfile(profile);
  }

  void _toggleFnLock(bool enable) {
    setState(() {
      _fnLock = enable;
      _status['fn_lock'] = enable;
    });
    _api.setFnLock(enable);
  }

  void _toggleFanBoost(bool enable) {
    setState(() {
      _status['fan_boost'] = enable;
      if (enable) {
        _status['fan_speeds'] = {
          'cpu_fan_pct': 100,
          'gpu_fan_pct': 100,
          'available': true,
        };
      }
    });
    _api.setFanBoost(enable);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('scaffold_${I18n.currentLocale}'),
      body: Row(
        children: [
          // Left Sidebar Navigation
          _buildSidebar(),
          // Main Body Content
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      LightingView(
                        api: _api,
                        status: _status,
                        lightsEnabled: _lightsEnabled,
                        selectedEffect: _selectedEffect,
                        speed: _speed,
                        primaryColor: _primaryColor,
                        secondaryColor: _secondaryColor,
                        brightness: _brightness,
                        onEffectChanged: _applyEffect,
                        onToggleLights: _toggleLights,
                        onBrightnessChanged: _updateBrightness,
                      ),
                      PerformanceView(
                        api: _api,
                        powerProfile: _powerProfile,
                        fnLock: _fnLock,
                        status: _status,
                        onPowerProfileChanged: _updatePowerProfile,
                        onFnLockChanged: _toggleFnLock,
                        onFanBoostChanged: _toggleFanBoost,
                      ),
                      SystemMonitorView(
                        status: _status,
                      ),
                      BatteryView(
                        status: _status,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF13161F),
        border: Border(right: BorderSide(color: Color(0xFF222736), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          // Logo & Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF7000FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/thunderobot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.bolt, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'THUNDEROBOT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'CONTROL CENTER',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Navigation tabs
          _sidebarItem(0, I18n.tr('tab_lighting'), Icons.keyboard_alt_outlined),
          _sidebarItem(1, I18n.tr('tab_performance'), Icons.speed_outlined),
          _sidebarItem(2, I18n.tr('tab_monitor'), Icons.analytics_outlined),
          _sidebarItem(3, I18n.tr('tab_battery'), Icons.battery_charging_full_outlined),
          const Spacer(),
          // Connection status indicator & Manual Reconnect Button
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1F2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _connected
                    ? const Color(0xFF00E5FF).withOpacity(0.3)
                    : (_isReconnecting ? const Color(0xFFFF9900).withOpacity(0.4) : Colors.redAccent.withOpacity(0.4)),
              ),
            ),
            child: Row(
              children: [
                _isReconnecting
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9900)),
                      )
                    : CircleAvatar(
                        radius: 5,
                        backgroundColor: _connected ? const Color(0xFF00FF88) : Colors.redAccent,
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _connected
                        ? I18n.tr('engine_active')
                        : (_isReconnecting ? I18n.tr('reconnecting') : I18n.tr('disconnected')),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _connected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
                if (!_connected || _isReconnecting)
                  InkWell(
                    onTap: _isReconnecting ? null : _restartAndReconnect,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 14,
                            color: _isReconnecting ? Colors.white38 : const Color(0xFF00E5FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            I18n.tr('reconnect'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _isReconnecting ? Colors.white38 : const Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String title, IconData icon) {
    final active = _currentTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentTab = index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF00E5FF).withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? const Color(0xFF00E5FF) : Colors.white54,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final cpuTemp = _status['cpu_temp'] ?? 0.0;
    final gpuTemp = _status['gpu_temp'] ?? 0.0;
    final batCap = _status['battery']?['capacity'] ?? 0;

    String title;
    switch (_currentTab) {
      case 0:
        title = I18n.tr('tab_lighting');
        break;
      case 1:
        title = I18n.tr('tab_performance');
        break;
      case 2:
        title = I18n.tr('tab_monitor');
        break;
      case 3:
      default:
        title = I18n.tr('tab_battery');
        break;
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: const Color(0xFF13161F),
        border: Border(bottom: BorderSide(color: Color(0xFF222736), width: 1)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          _buildLanguageSwitcher(),
          const SizedBox(width: 14),
          _quickPill(Icons.memory, 'CPU: ${cpuTemp}°C', const Color(0xFF00E5FF)),
          const SizedBox(width: 12),
          _quickPill(Icons.sports_esports, 'GPU: ${gpuTemp}°C', const Color(0xFFFF007F)),
          const SizedBox(width: 12),
          _quickPill(Icons.battery_std, '$batCap%', const Color(0xFF00FF88)),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    final current = I18n.currentLocale;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 6),
            child: Icon(Icons.language, size: 15, color: Color(0xFF00E5FF)),
          ),
          _langOption('es', 'ES', current == 'es'),
          Container(width: 1, height: 14, color: Colors.white24),
          _langOption('en', 'EN', current == 'en'),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _langOption(String locale, String label, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSelected ? null : () => I18n.setLocale(locale),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
