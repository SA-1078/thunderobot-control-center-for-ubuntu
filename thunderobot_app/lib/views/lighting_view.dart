import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/i18n_service.dart';
import '../widgets/color_matrix.dart';

class LightingView extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic> status;
  final bool lightsEnabled;
  final String selectedEffect;
  final double speed;
  final Color primaryColor;
  final Color secondaryColor;
  final int brightness;
  final Function(String effect, double speed, Color primary, Color secondary) onEffectChanged;
  final Function(bool enabled) onToggleLights;
  final Function(int level) onBrightnessChanged;

  const LightingView({
    super.key,
    required this.api,
    required this.status,
    required this.lightsEnabled,
    required this.selectedEffect,
    required this.speed,
    required this.primaryColor,
    required this.secondaryColor,
    required this.brightness,
    required this.onEffectChanged,
    required this.onToggleLights,
    required this.onBrightnessChanged,
  });

  @override
  State<LightingView> createState() => _LightingViewState();
}

class _LightingViewState extends State<LightingView> {
  // Lighting sub-mode: 0 = Monocolor, 1 = Colorful (Rainbow), 2 = Manual (Sequence), 3 = Special Effects
  int _lightingSubMode = 0;

  // Manual sequence colors (up to 6 slots matching Windows reference)
  final List<Color> _manualSlots = [
    const Color(0xFF00E5FF),
    const Color(0xFFFF9900),
    const Color(0xFFFFFF00),
    const Color(0xFF00FF00),
    const Color(0xFF0000FF),
    const Color(0xFFFF00FF),
  ];
  int _activeManualSlot = 0;

  @override
  void initState() {
    super.initState();
    _syncSubMode();
  }

  @override
  void didUpdateWidget(LightingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedEffect != widget.selectedEffect) {
      _syncSubMode();
    }
  }

  void _syncSubMode() {
    if (widget.selectedEffect == 'static') {
      _lightingSubMode = 0; // Monocolor
    } else if (widget.selectedEffect == 'rainbow') {
      _lightingSubMode = 1; // Colorful
    } else if (widget.selectedEffect == 'color_cycle') {
      _lightingSubMode = 2; // Manual / Multi-color
    } else {
      _lightingSubMode = 3; // Special (Breathing, CPU Temp)
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Master Power Switch (Matching Windows Layout)
          _buildHeaderBanner(),
          const SizedBox(height: 24),

          // 3 Main Mode Selectors matching Windows reference
          _buildModeSelectorTabs(),
          const SizedBox(height: 24),

          // Main Interactive Configuration Panel
          _buildActiveModePanel(),
          const SizedBox(height: 28),

          // Brightness Control Slider (Present in all modes)
          _buildBrightnessSlider(),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.lightsEnabled ? widget.primaryColor.withOpacity(0.5) : const Color(0xFF222736),
          width: 1.5,
        ),
        boxShadow: widget.lightsEnabled
            ? [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Power toggle switch
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: widget.lightsEnabled,
              activeColor: const Color(0xFF00E5FF),
              activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: const Color(0xFF222736),
              onChanged: (val) => widget.onToggleLights(val),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.tr('kb_logo_light'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lightsEnabled
                      ? I18n.tr('kb_light_on_hint', {'brightness': '${widget.brightness}'})
                      : I18n.tr('kb_light_off_hint'),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
          // Restore / Default button
          OutlinedButton.icon(
            onPressed: () {
              widget.onEffectChanged('rainbow', 1.0, const Color(0xFF00E5FF), const Color(0xFFFF007F));
              widget.onBrightnessChanged(4);
              widget.onToggleLights(true);
            },
            icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF00E5FF)),
            label: Text(I18n.tr('restore'), style: const TextStyle(color: Color(0xFF00E5FF))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00E5FF)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectorTabs() {
    return Row(
      children: [
        _modeTabButton(
          index: 0,
          label: I18n.tr('monocolor_tab'),
          tooltip: I18n.tr('monocolor_tooltip'),
          icon: Icons.format_paint_outlined,
          onTap: () {
            setState(() => _lightingSubMode = 0);
            widget.onEffectChanged('static', widget.speed, widget.primaryColor, widget.secondaryColor);
          },
        ),
        const SizedBox(width: 14),
        _modeTabButton(
          index: 1,
          label: I18n.tr('colorful_tab'),
          tooltip: I18n.tr('colorful_tooltip'),
          icon: Icons.all_inclusive_outlined,
          onTap: () {
            setState(() => _lightingSubMode = 1);
            widget.onEffectChanged('rainbow', widget.speed, widget.primaryColor, widget.secondaryColor);
          },
        ),
        const SizedBox(width: 14),
        _modeTabButton(
          index: 2,
          label: I18n.tr('manual_tab'),
          tooltip: I18n.tr('manual_tooltip'),
          icon: Icons.layers_outlined,
          onTap: () {
            setState(() => _lightingSubMode = 2);
            widget.onEffectChanged('color_cycle', widget.speed, _manualSlots[0], _manualSlots[1]);
          },
        ),
        const SizedBox(width: 14),
        _modeTabButton(
          index: 3,
          label: I18n.tr('special_tab'),
          tooltip: I18n.tr('special_tooltip'),
          icon: Icons.auto_awesome_outlined,
          onTap: () {
            setState(() => _lightingSubMode = 3);
            widget.onEffectChanged('breathing', widget.speed, widget.primaryColor, widget.secondaryColor);
          },
        ),
      ],
    );
  }

  Widget _modeTabButton({
    required int index,
    required String label,
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final active = _lightingSubMode == index;
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF00E5FF).withOpacity(0.12) : const Color(0xFF13161F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? const Color(0xFF00E5FF) : const Color(0xFF222736),
                  width: active ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: active ? const Color(0xFF00E5FF) : Colors.white60),
                  const SizedBox(width: 10),
                  Text(
                    label,
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
      ),
    );
  }

  Widget _buildActiveModePanel() {
    switch (_lightingSubMode) {
      case 0:
        return _buildMonocolorPanel();
      case 1:
        return _buildColorfulPanel();
      case 2:
        return _buildManualSequencePanel();
      case 3:
      default:
        return _buildSpecialEffectsPanel();
    }
  }

  Widget _buildMonocolorPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: widget.primaryColor.withOpacity(0.6), blurRadius: 10),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18n.tr('monocolor_title'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      I18n.tr('monocolor_desc'),
                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ColorMatrix(
            selectedColor: widget.primaryColor,
            onColorSelected: (newColor) {
              widget.onEffectChanged('static', widget.speed, newColor, widget.secondaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.tr('colorful_title'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            I18n.tr('colorful_desc'),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 20),
          // Gradient preview bar
          Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFF8000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSpeedSlider(I18n.tr('speed_color_change')),
        ],
      ),
    );
  }

  Widget _buildManualSequencePanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.tr('manual_title'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            I18n.tr('manual_desc'),
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 18),
          // 6 Custom color slots matching Windows screenshot
          Row(
            children: List.generate(_manualSlots.length, (i) {
              final isCurrent = _activeManualSlot == i;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _activeManualSlot = i),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _manualSlots[i],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent ? Colors.white : Colors.white24,
                          width: isCurrent ? 3 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: _manualSlots[i].withOpacity(0.7),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: isCurrent
                          ? const Center(
                              child: Icon(Icons.colorize, size: 20, color: Colors.black87),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          ColorMatrix(
            selectedColor: _manualSlots[_activeManualSlot],
            onColorSelected: (color) {
              setState(() {
                _manualSlots[_activeManualSlot] = color;
              });
              final c1 = _manualSlots[0];
              final c2 = _manualSlots[1];
              widget.onEffectChanged('color_cycle', widget.speed, c1, c2);
            },
          ),
          const SizedBox(height: 20),
          _buildSpeedSlider(I18n.tr('manual_interval')),
        ],
      ),
    );
  }

  Widget _buildSpecialEffectsPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.tr('special_title'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _specialEffectCard(
                  effect: 'breathing',
                  title: I18n.tr('breathing_title'),
                  description: I18n.tr('breathing_desc'),
                  icon: Icons.air,
                  active: widget.selectedEffect == 'breathing',
                  onTap: () {
                    widget.onEffectChanged('breathing', widget.speed, widget.primaryColor, widget.secondaryColor);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _specialEffectCard(
                  effect: 'cpu_temp',
                  title: I18n.tr('thermal_title'),
                  description: I18n.tr('thermal_desc'),
                  icon: Icons.thermostat,
                  active: widget.selectedEffect == 'cpu_temp',
                  onTap: () {
                    widget.onEffectChanged('cpu_temp', widget.speed, widget.primaryColor, widget.secondaryColor);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSpeedSlider(I18n.tr('speed_effect')),
        ],
      ),
    );
  }

  Widget _specialEffectCard({
    required String effect,
    required String title,
    required String description,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E5FF).withOpacity(0.12) : const Color(0xFF1B1F2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF00E5FF) : const Color(0xFF2E3446),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: active ? const Color(0xFF00E5FF) : Colors.white60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedSlider(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            Text('${widget.speed.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
          ],
        ),
        Slider(
          value: widget.speed,
          min: 0.2,
          max: 3.0,
          divisions: 14,
          activeColor: const Color(0xFF00E5FF),
          inactiveColor: const Color(0xFF222736),
          onChanged: (v) {
            widget.onEffectChanged(widget.selectedEffect, v, widget.primaryColor, widget.secondaryColor);
          },
        ),
      ],
    );
  }

  Widget _buildBrightnessSlider() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF13161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222736)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                I18n.tr('brightness_title'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${widget.brightness} / 4',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00E5FF)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: widget.brightness.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: const Color(0xFF222736),
            onChanged: (v) => widget.onBrightnessChanged(v.toInt()),
          ),
          Text(
            I18n.tr('brightness_hint'),
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
