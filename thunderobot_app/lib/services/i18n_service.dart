import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class I18n {
  static String currentLocale = 'es';
  static final ValueNotifier<String> localeNotifier = ValueNotifier<String>('es');

  static final Map<String, Map<String, String>> _strings = {
    'es': {
      // General & Header
      'app_title': 'THUNDEROBOT',
      'control_center': 'CENTRO DE CONTROL',
      'engine_active': 'Motor Activo',
      'disconnected': 'Desconectado',
      'reconnecting': 'Reconectando...',
      'reconnect': 'Reconectar',
      'language': 'Idioma',
      'offline_banner': 'El servicio backend local no responde. El sistema intentará autoreconectarse.',

      // Tabs & Header Titles
      'tab_lighting': 'Iluminación Teclado',
      'tab_performance': 'Modo Rendimiento',
      'tab_monitor': 'Monitor del Sistema',
      'tab_battery': 'Batería y Energía',

      // Performance Mode
      'mode_selecting': 'Selección de Modo',
      'mode_subtitle': 'Perfiles de Rendimiento y Curvas de Ventilador',
      'cpu_temp_title': 'Temperatura CPU (Ryzen 7 7745HX)',
      'gpu_temp_title': 'Temperatura GPU (RTX 5070)',
      'fan_boost_title': 'Fan Boost (Ventiladores al 100%)',
      'fan_boost_active': 'BOOST ACTIVO (100%)',
      'fan_boost_auto': 'AUTOMÁTICO',
      'fan_boost_ec_auto': 'EC AUTO ({cpu}% / {gpu}%)',
      'fan_boost_desc': 'Activa la máxima velocidad de disipación de ambos ventiladores para enfriar el equipo de inmediato.',
      'fan_telemetry_desc': 'Telemetría de ventiladores: CPU {cpu}% | GPU {gpu}%. Activa el boost para llevar ambos al 100% inmediato.',

      'office_mode_title': 'Modo Oficina (Silencioso)',
      'office_mode_desc': 'Entorno silencioso y confortable. Reduce el consumo energético y mantiene los ventiladores en su mínimo nivel sonoro para trabajo o estudio.',
      'perf_mode_title': 'Modo Rendimiento (Recomendado)',
      'perf_mode_desc': 'El sistema gestiona automáticamente la velocidad de los ventiladores para enfriar de forma óptima. Máxima potencia para juegos y renderizado.',
      'balanced_mode_title': 'Modo Equilibrado',
      'balanced_mode_desc': 'Equilibrio dinámico óptimo entre rendimiento térmico y acústica para uso general diario.',

      'custom_mode_title': 'Ajuste de Modo Personalizado',
      'custom_mode_desc': 'Personaliza el mejor rendimiento para tu escenario de juego.',
      'customize_btn': 'Personalizar',
      'ok_btn': 'Aplicar',
      'profile_applied': '{profile} aplicado correctamente.',
      'customize_dialog_title': 'Personalizar {profile} (Ajustes de Ventilador)',
      'customize_dialog_desc': 'Ajusta la curva de velocidad de los ventiladores para este perfil personalizado.',
      'cpu_fan_speed': 'Velocidad Ventilador CPU',
      'gpu_fan_speed': 'Velocidad Ventilador GPU',
      'save_profile': 'Guardar Perfil',
      'cancel': 'Cancelar',

      'fn_lock_title': 'Bloqueo de Teclas Fn (Fn Lock)',
      'fn_lock_desc': 'Invierte el comportamiento de la fila superior (F1-F12 vs funciones multimedia / brillo / volumen).',

      // Lighting
      'kb_logo_light': 'Iluminación Teclado y Logo',
      'kb_light_on_hint': 'Haz clic en el interruptor para encender/apagar la luz del teclado. (Activo • Brillo {brightness}/4)',
      'kb_light_off_hint': 'El teclado está apagado. Activa el interruptor o presiona Fn + F7.',
      'restore': 'Restaurar',
      'monocolor_tab': 'Monocolor',
      'monocolor_tooltip': 'Color estático fijo seleccionado de la paleta',
      'colorful_tab': 'Colorido (Arcoíris)',
      'colorful_tooltip': 'Ciclo dinámico y fluido de todos los colores',
      'manual_tab': 'Manual / Secuencia',
      'manual_tooltip': 'Transición entre colores personalizados',
      'special_tab': 'Efectos Especiales',
      'special_tooltip': 'Modo Respiración y Reactivo Térmico',
      'monocolor_title': 'Modo Monocolor (Color Sólido)',
      'monocolor_desc': 'Elige cualquiera de los 32 colores preestablecidos para iluminar todo el teclado.',
      'colorful_title': 'Modo Colorido (Efecto Arcoíris 360°)',
      'colorful_desc': 'El teclado transiciona suavemente por todo el espectro RGB cromático de forma ininterrumpida.',
      'speed_color_change': 'Velocidad de Cambio de Color',
      'manual_title': 'Modo Manual (Secuencia de Colores)',
      'manual_desc': 'Selecciona una casilla para asignarle un color de la matriz y ajustar el intervalo de cambio.',
      'manual_interval': 'Intervalo de transición de color',
      'special_title': 'Efectos Dinámicos Avanzados',
      'breathing_title': 'Respiración Suave',
      'breathing_desc': 'Pulsación orgánica que inhala y exhala suavemente.',
      'thermal_title': 'Reactivo Térmico',
      'thermal_desc': 'Cambia de color según la temperatura de la CPU (Cian → Ámbar → Rojo).',
      'speed_effect': 'Velocidad del Efecto',
      'brightness_title': 'Nivel de Brillo del Teclado',
      'brightness_hint': 'Nota: Puedes ajustar el brillo en cualquier momento con las teclas físicas Fn + F6 / Fn + F7.',

      // Monitor
      'sys_info_title': 'Información del Sistema',
      'sys_info_subtitle': 'Especificaciones de Hardware y Sensores en Tiempo Real',
      'cpu_info_title': 'Información del Procesador (CPU)',
      'cpu_info_specs': 'AMD Ryzen 7 7745HX with Radeon Graphics\n8 núcleos, 16 hilos • Máx 5.1 GHz',
      'gpu_info_title': 'Información Gráfica (GPU)',
      'gpu_info_specs': 'NVIDIA GeForce RTX 5070 Laptop GPU (8GB GDDR7)\nAMD Radeon(TM) 610M Gráficos Integrados (Modo Híbrido)',
      'memory_info_title': 'Información de Memoria (RAM)',
      'memory_info_specs': '32 GB DDR5 Alta Velocidad Dual-Channel RAM',
      'sys_monitor_title': 'Monitor de Sensores',
      'metric_cpu_temp': 'Temp CPU',
      'metric_gpu_temp': 'Temp GPU',
      'metric_cpu_fan': 'Ventilador CPU',
      'metric_gpu_fan': 'Ventilador GPU',
      'metric_battery': 'Batería',
      'metric_power_state': 'Estado Carga',
      'charging': 'Cargando',
      'discharging': 'Batería',
      'full': 'Completa',

      // Battery
      'battery_title': 'Batería y Energía',
      'battery_subtitle': 'Telemetría en tiempo real y estado eléctrico de la batería (Modo Solo Lectura Seguro)',
      'safe_mode_notice_title': 'Gestión de Carga 100% Segura por Hardware (BIOS)',
      'safe_mode_notice_desc': 'El software opera en modo de solo lectura para evitar interferencias con el microcontrolador de la placa base. Tu batería carga libremente hasta el 100% con la máxima protección nativa.',
      'charger_connected': 'CARGADOR CONECTADO',
      'on_battery': 'EN USO CON BATERÍA',
      'system_status': 'Estado del sistema: {status}',
      'charging_desc': 'Suministrando energía continua al equipo y cargando las celdas.',
      'discharging_desc': 'El equipo está alimentándose exclusivamente de la batería interna.',
      'sensors_header': 'SENSORES DE ENERGÍA Y CORRIENTE',
      'power_metric': 'Potencia Eléctrica',
      'voltage_metric': 'Voltaje de Celdas',
      'current_metric': 'Corriente de Flujo',
    },
    'en': {
      // General & Header
      'app_title': 'THUNDEROBOT',
      'control_center': 'CONTROL CENTER',
      'engine_active': 'Engine Active',
      'disconnected': 'Disconnected',
      'reconnecting': 'Reconnecting...',
      'reconnect': 'Reconnect',
      'language': 'Language',
      'offline_banner': 'Local backend service is unreachable. Auto-recovery is attempting to reconnect.',

      // Tabs & Header Titles
      'tab_lighting': 'Keyboard Light',
      'tab_performance': 'Performance Mode',
      'tab_monitor': 'System Monitor',
      'tab_battery': 'Battery & Power',

      // Performance Mode
      'mode_selecting': 'Mode Selecting',
      'mode_subtitle': 'Performance Mode & Fan Curves',
      'cpu_temp_title': 'CPU Temperature (Ryzen 7 7745HX)',
      'gpu_temp_title': 'GPU Temperature (RTX 5070)',
      'fan_boost_title': 'Fan Boost (100% Fans)',
      'fan_boost_active': 'BOOST ACTIVE (100%)',
      'fan_boost_auto': 'AUTO',
      'fan_boost_ec_auto': 'EC AUTO ({cpu}% / {gpu}%)',
      'fan_boost_desc': 'Forces maximum cooling fan speed to rapidly dissipate heat.',
      'fan_telemetry_desc': 'Fan telemetry: CPU {cpu}% | GPU {gpu}%. Activate boost to immediately set both to 100%.',

      'office_mode_title': 'Office Mode (Quiet)',
      'office_mode_desc': 'Quiet and comfortable environment. Reduces power consumption and keeps fans at minimum noise level for work or study.',
      'perf_mode_title': 'Performance Mode (Recommended)',
      'perf_mode_desc': 'The system will automatically manage fan speeds to properly cool your computer. Recommended mode for maximum gaming and render output.',
      'balanced_mode_title': 'Balanced Mode',
      'balanced_mode_desc': 'Optimal dynamic balance between thermal performance and acoustics for daily general use.',

      'custom_mode_title': 'Custom Mode Setting',
      'custom_mode_desc': 'Customize the best performance for your gaming scenario.',
      'customize_btn': 'Customize',
      'ok_btn': 'Apply',
      'profile_applied': '{profile} applied successfully.',
      'customize_dialog_title': 'Customize {profile} (Fan Settings)',
      'customize_dialog_desc': 'Adjust the fan speed curve for this custom profile.',
      'cpu_fan_speed': 'CPU Fan Speed',
      'gpu_fan_speed': 'GPU Fan Speed',
      'save_profile': 'Save Profile',
      'cancel': 'Cancel',

      'fn_lock_title': 'Fn Key Lock',
      'fn_lock_desc': 'Inverts the top row behavior (F1-F12 vs multimedia / brightness / volume shortcuts).',

      // Lighting
      'kb_logo_light': 'Keyboard & Logo Light',
      'kb_light_on_hint': 'Click switch to turn ON/OFF keyboard lighting. (Active • Brightness {brightness}/4)',
      'kb_light_off_hint': 'Keyboard lighting is OFF. Flip switch or press Fn + F7.',
      'restore': 'Restore',
      'monocolor_tab': 'Monocolor',
      'monocolor_tooltip': 'Fixed static color selected from palette',
      'colorful_tab': 'Colorful (Rainbow)',
      'colorful_tooltip': 'Smooth dynamic cycle of all colors',
      'manual_tab': 'Manual / Sequence',
      'manual_tooltip': 'Transition between custom colors',
      'special_tab': 'Special Effects',
      'special_tooltip': 'Breathing and Thermal Reactive modes',
      'monocolor_title': 'Monocolor Mode (Solid Color)',
      'monocolor_desc': 'Choose any of the 32 preset colors to illuminate the keyboard.',
      'colorful_title': 'Colorful Mode (360° Rainbow Effect)',
      'colorful_desc': 'Keyboard smoothly transitions through the entire RGB spectrum continuously.',
      'speed_color_change': 'Color Cycle Speed',
      'manual_title': 'Manual Mode (Color Sequence)',
      'manual_desc': 'Select a slot to assign a color from the matrix and adjust cycle speed.',
      'manual_interval': 'Color change interval',
      'special_title': 'Advanced Dynamic Effects',
      'breathing_title': 'Smooth Breathing',
      'breathing_desc': 'Organic pulsing effect that smoothly inhales and exhales.',
      'thermal_title': 'Thermal Reactive',
      'thermal_desc': 'Changes color based on CPU temperature (Cyan → Amber → Red).',
      'speed_effect': 'Effect Speed',
      'brightness_title': 'Keyboard Brightness Level',
      'brightness_hint': 'Note: You can adjust brightness anytime using physical keys Fn + F6 / Fn + F7.',

      // Monitor
      'sys_info_title': 'System Information',
      'sys_info_subtitle': 'Hardware Specifications & Real-time Sensors',
      'cpu_info_title': 'Processor Information (CPU)',
      'cpu_info_specs': 'AMD Ryzen 7 7745HX with Radeon Graphics\n8 Core(s), 16 Threads • Max 5.1 GHz',
      'gpu_info_title': 'Graphics Information (GPU)',
      'gpu_info_specs': 'NVIDIA GeForce RTX 5070 Laptop GPU (8GB GDDR7)\nAMD Radeon(TM) 610M Integrated Graphics (Hybrid Mode)',
      'memory_info_title': 'Memory Information (RAM)',
      'memory_info_specs': '32 GB DDR5 High Speed Dual-Channel RAM',
      'sys_monitor_title': 'Sensors Monitor',
      'metric_cpu_temp': 'CPU Temp',
      'metric_gpu_temp': 'GPU Temp',
      'metric_cpu_fan': 'CPU Fan',
      'metric_gpu_fan': 'GPU Fan',
      'metric_battery': 'Battery',
      'metric_power_state': 'Charging Status',
      'charging': 'Charging',
      'discharging': 'On Battery',
      'full': 'Full',

      // Battery
      'battery_title': 'Battery & Power',
      'battery_subtitle': 'Real-time telemetry and battery electrical status (Safe Read-Only Mode)',
      'safe_mode_notice_title': 'Hardware-Safe Factory Charging Management (BIOS)',
      'safe_mode_notice_desc': 'Software operates in read-only mode to prevent interference with motherboard embedded controllers. Your battery charges safely up to 100% with factory protection.',
      'charger_connected': 'CHARGER CONNECTED',
      'on_battery': 'ON BATTERY',
      'system_status': 'System status: {status}',
      'charging_desc': 'Providing continuous power to device and charging battery cells.',
      'discharging_desc': 'Device is running exclusively on internal battery power.',
      'sensors_header': 'POWER & CURRENT SENSORS',
      'power_metric': 'Power Rate',
      'voltage_metric': 'Cell Voltage',
      'current_metric': 'Current Flow',
    }
  };

  static String tr(String key, [Map<String, String>? params]) {
    String text = _strings[currentLocale]?[key] ?? _strings['es']?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }

  static void setLocale(String locale) {
    if (locale != 'es' && locale != 'en') return;
    if (currentLocale == locale) return;
    currentLocale = locale;
    localeNotifier.value = locale;
    Future.microtask(() => _savePreference(locale));
  }

  static void toggleLocale() {
    setLocale(currentLocale == 'es' ? 'en' : 'es');
  }

  static Future<void> loadPreference() async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final configFile = File('$home/.config/thunderobot/app_settings.json');
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final data = json.decode(content);
        if (data['language'] != null) {
          currentLocale = data['language'];
          localeNotifier.value = currentLocale;
        }
      }
    } catch (_) {}
  }

  static Future<void> _savePreference(String locale) async {
    try {
      final home = Platform.environment['HOME'] ?? '';
      final dir = Directory('$home/.config/thunderobot');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final configFile = File('$home/.config/thunderobot/app_settings.json');
      await configFile.writeAsString(json.encode({'language': locale}));
    } catch (_) {}
  }
}
