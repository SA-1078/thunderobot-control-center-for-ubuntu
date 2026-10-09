# Thunderobot Control Center para Linux (Ubuntu)
### Diseñado específicamente para Thunderobot RS16 (AMD Ryzen 7 7745HX + NVIDIA RTX 5070 Laptop)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Linux/Ubuntu](https://img.shields.io/badge/Platform-Ubuntu%20Linux-E95420.svg)](#-requisitos-previos)
[![Tested On: Thunderobot RS16](https://img.shields.io/badge/Device-Thunderobot%20RS16-blueviolet.svg)](#-compatibilidad-de-hardware-y-advertencia)
[![CPU: AMD Ryzen 7 7745HX](https://img.shields.io/badge/CPU-Ryzen%207%207745HX-ED1C24.svg)](#-compatibilidad-de-hardware-y-advertencia)
[![GPU: NVIDIA RTX 5070](https://img.shields.io/badge/GPU-RTX%205070%20Laptop-76B900.svg)](#-compatibilidad-de-hardware-y-advertencia)
[![UI: Flutter](https://img.shields.io/badge/UI-Flutter%20Desktop-02569B.svg)](#-estructura-del-repositorio)
[![Backend: Python](https://img.shields.io/badge/Backend-Python%203-3776AB.svg)](#-estructura-del-repositorio)

Centro de Control nativo, moderno y modular desarrollado en **Flutter (UI)** y **Python (Motor & HAL)** para laptops **Thunderobot RS16** (chasis Uniwill / Tongfang con procesadores AMD Ryzen y gráficos NVIDIA GeForce RTX).

Diseñado específicamente como un reemplazo de alto rendimiento y código abierto para el Control Center original de Windows, optimizado para Linux sin requerir privilegios de superusuario en la sesión diaria.

---

<a id="compatibilidad"></a>
## ⚠️ Compatibilidad de Hardware y Advertencia

> [!IMPORTANT]
> **Equipo de Referencia Oficial:**
> Este software fue desarrollado, calibrado y probado específicamente para el modelo:
> * **Laptop:** **Thunderobot RS16**
> * **Procesador (CPU):** **AMD Ryzen 7 7745HX with Radeon Graphics**
> * **Tarjeta Gráfica Dedicada (GPU):** **NVIDIA GeForce RTX 5070 Laptop GPU**
> * **Placa base / Chasis:** Arquitectura OEM Uniwill / Tongfang

> [!WARNING]
> **Aviso de compatibilidad para otros equipos:**
> El control térmico y de ventiladores interactúa directamente con los registros de memoria RAM del **Embedded Controller (EC)** a nivel de hardware.
> En **otros modelos de laptop Thunderobot** o variantes con diferente placa base, procesador o versión de firmware/EC, **es posible que no funcione de la misma manera**, que los ventiladores respondan a diferentes offsets o que ciertas funciones de telemetría no estén disponibles.

---

## 📑 Tabla de Contenidos

* [⚠️ Compatibilidad de Hardware y Advertencia](#️-compatibilidad-de-hardware-y-advertencia)
* [🔄 Comparativa Respecto a Windows](#-comparativa-y-cambios-respecto-a-la-versión-de-windows)
* [🚀 Características Principales](#-características-principales)
  * [1. Modos de Rendimiento y Curvas de Ventilador](#1-modos-de-rendimiento-y-curvas-de-ventilador)
  * [2. Iluminación RGB del Teclado](#2-iluminación-rgb-del-teclado)
  * [3. Internacionalización Global (Español / Inglés)](#3-internacionalización-global-español--inglés)
  * [4. Monitor del Sistema y Sensores](#4-monitor-del-sistema-y-sensores)
* [📦 Estructura del Repositorio](#-estructura-del-repositorio)
* [🛠️ Instalación en Ubuntu](#-instalación-en-ubuntu)
  * [Requisitos Previos](#-requisitos-previos)
  * [Paso 1: Clonar el repositorio](#paso-1-clonar-el-repositorio)
  * [Paso 2: Ejecutar el instalador](#paso-2-ejecutar-el-instalador)
* [🖥️ Cómo Ejecutar la Aplicación](#-cómo-ejecutar-la-aplicación)
* [🔧 Gestión del Servicio en Segundo Plano](#-gestión-del-servicio-en-segundo-plano)
* [🗑️ Desinstalación](#-desinstalación)
* [💻 Desarrollo Local (Dev Mode)](#-desarrollo-local-dev-mode)
* [📄 Licencia](#-licencia)

---

<a id="comparativa"></a>
## 🔄 Comparativa y Cambios Respecto a la Versión de Windows

A continuación se detallan las mejoras técnicas y arquitectónicas implementadas al adaptar el software de Windows a Linux:

| Característica | Versión Windows (OEM Original) | Versión Linux (Este Proyecto) |
| :--- | :--- | :--- |
| **Arquitectura** | Aplicación UWP monolítica (`GamingCenter3_Cross.UWP`), puente `GCUBridge.exe`, servicios residentes de alto consumo (~300-500 MB RAM). | Desacoplada: Demonio de hardware ligero en Python (~25 MB RAM) + UI nativa Flutter con aceleración gráfica GTK. |
| **Control de Ventiladores** | Llamadas cerradas ACPI/WMI vía DLLs privativas (`UEFI_Firmware.dll`). | Lectura y escritura directa en registros de memoria RAM del Embedded Controller (EC) mediante `/dev/tuxedo_io`. |
| **Fan Boost (100%)** | Botón en interfaz que depende de servicios pesados de Windows. | Conmutador inmediato directo al hardware (`IOCTL_W_UW_FANBOOST`) que lleva ambos ventiladores al 100% físico al instante. |
| **Telemetría de Ventiladores** | Indicadores visuales aproximados o lentos. | Hilo asíncrono en segundo plano que consulta el EC cada 2s sin bloquear peticiones web: muestra el % de giro real (~26-30% en reposo, 100% en boost). |
| **Perfiles de Rendimiento** | Perfiles OEM con modificación de voltajes en Windows. | Integrado con perfiles de Linux y modos nativos del EC (`IOCTL_W_UW_PERF_PROF`): Oficina (Silencioso), Equilibrado y Rendimiento. |
| **Iluminación RGB** | Comandos propietarios que pueden desincronizarse al suspender el equipo. | Control directo a través del subsistema del kernel (`sysfs multi_intensity`) con algoritmos armónicos de interpolación suave (Rainbow, Respiración, Reactivo Térmico). |
| **Teclas Físicas de Brillo** | A veces bloquean la animación RGB tras pulsar `Fn + F6/F7`. | Escala armónica que respeta la animación activa y permite apagar o graduar el brillo en tiempo real con las teclas físicas. |
| **Idiomas** | Textos con traducciones mixtas o incompletas (inglés/chino). | Conmutador global **Español / Inglés** instantáneo (< 16 ms) que traduce toda la suite en tiempo real y recuerda tu preferencia. |

---

<a id="caracteristicas"></a>
## 🚀 Características Principales

<a id="ventiladores"></a>
### 1. 🎛️ Modos de Rendimiento y Curvas de Ventilador
* **Modos de Energía de Hardware:**
  * **Modo Oficina (Silencioso):** Mantiene los ventiladores en su umbral mínimo acústico, ideal para trabajo de oficina y estudio.
  * **Modo Rendimiento (Recomendado):** Permite al firmware y al controlador exprimir la potencia del CPU y GPU para gaming y tareas pesadas.
  * **Modo Equilibrado:** Balance óptimo dinámico entre rendimiento térmico y acústica para uso general diario.
* **Fan Boost (100% Ventiladores):**
  * Conmutador inmediato que fuerza ambos ventiladores al 100% de su capacidad física para disipación térmica ultrarrápida.
* **Perfiles Personalizados (Custom Mode):**
  * Selector de 4 perfiles independientes con ajuste de curvas de ventilador personalizadas (CPU / GPU Fan Speed) replicando la versión de Windows.
* **Telemetría EC en Tiempo Real:**
  * Monitorización continua y no bloqueante de la velocidad física de giro de ventiladores (`CPU Fan %` y `GPU Fan %`) directamente desde la memoria RAM del Embedded Controller (EC).
* **Bloqueo de Teclas Fn (Fn Lock):**
  * Invierte el comportamiento de la fila superior entre teclas de función F1-F12 estándar o accesos directos multimedia.

<a id="rgb"></a>
### 2. 🌈 Iluminación RGB del Teclado
* **Modo Monocolor:** Paleta interactiva estilo Windows con 32 colores preestablecidos.
* **Modo Colorful (Arcoíris 360°):** Transición cromática suave y fluida con deslizador de velocidad.
* **Modo Manual (Secuencia):** Secuencia de hasta 6 ranuras de color personalizables con ajuste de intervalo de transición.
* **Efectos Dinámicos Avanzados:**
  * **Respiración Armónica (Breathing):** Inhalación y exhalación sedosa.
  * **Reactivo Térmico (CPU Temp):** Gradiente en vivo de Cian → Ámbar → Rojo según la temperatura de la CPU.
* **Control de Brillo:** Deslizador de 0 a 4 niveles con soporte para las teclas físicas `Fn + F6` y `Fn + F7`.
* **Interruptor Maestro:** Apagado o encendido global con botón de restauración a valores por defecto.

<a id="idiomas"></a>
### 3. 🌐 Internacionalización Global (Español / Inglés)
* Conmutador de idioma instantáneo (`🌐 ES | EN`) en la barra superior.
* Cambio fluido en memoria en menos de **16 ms (1 frame)** sin recargar el motor ni perder el estado de las pestañas.
* Persistencia automática de la preferencia en `~/.config/thunderobot/app_settings.json`.

<a id="monitor"></a>
### 4. 📊 Monitor del Sistema y Sensores
* **Especificaciones del Hardware:** Detección de procesador (AMD Ryzen), tarjeta gráfica (NVIDIA RTX) y memoria RAM.
* **Medidores Circulares en Vivo:** Temperatura de CPU, Temperatura de GPU, y porcentaje de ventiladores (CPU y GPU).



<a id="estructura"></a>
## 📦 Estructura del Repositorio

```text
.
├── LICENSE                             # Licencia de código abierto MIT
├── install.sh                          # Instalador automático en 1 paso para Ubuntu
├── uninstall.sh                        # Script de desinstalación limpia
├── setup_permissions.sh                # Configuración de reglas udev para hardware
├── launch_thunderobot.sh               # Lanzador manual / script de arranque
├── thunderobot-control-center.desktop  # Plantilla de acceso directo de escritorio
├── thunderobot.service                 # Servicio de usuario systemd
├── thunderobot_controller.py           # Punto de entrada del demonio en Python
├── thunderobot_core/                   # Paquete Python: Motor HAL y servidor local
│   ├── hal/                            # Abstracción de Hardware (thermal, ec_led)
│   ├── engine/                         # Algoritmos de efectos RGB y scheduler
│   └── daemon/                         # Servidor REST HTTP (127.0.0.1:18888)
├── thunderobot_app/                    # Aplicación de interfaz gráfica en Flutter
│   ├── lib/                            # Código Dart (main.dart, views, services, i18n)
│   ├── assets/thunderobot.png          # Icono oficial de la aplicación
│   └── pubspec.yaml                    # Configuración de dependencias y assets
└── README.md
```

---

<a id="instalacion"></a>
## 🛠️ Instalación en Ubuntu

<a id="requisitos-previos"></a>
### Requisitos Previos
* **Laptop de Referencia:** Thunderobot RS16 (Ryzen 7 7745HX + RTX 5070 Laptop) o chasis Uniwill equivalente.
* **Sistema Operativo:** Ubuntu 22.04 LTS, 24.04 LTS o derivados basados en Debian.
* **Controlador del chasis:** Driver de teclado/EC (`tuxedo-drivers` con soporte `/dev/tuxedo_io`).
* **Python 3:** Python 3.10 o superior con `psutil`.

### Paso 1: Clonar el repositorio
```bash
git clone https://github.com/TU_USUARIO/thunderobot-control-center-for-ubuntu.git
cd thunderobot-control-center-for-ubuntu
```

### Paso 2: Ejecutar el instalador
```bash
chmod +x install.sh
./install.sh
```

El instalador automáticamente:
1. Verifica dependencias del sistema (`python3-psutil`).
2. Compila o verifica el paquete de Flutter.
3. Despliega la aplicación en `~/.local/share/thunderobot-control-center/`.
4. Crea el ejecutable global en `~/.local/bin/thunderobot-control-center`.
5. Registra el acceso directo en el menú de aplicaciones de Ubuntu (`.desktop`).
6. Activa y arranca el servicio en segundo plano `thunderobot.service` con systemd de usuario.
7. Aplica los permisos de hardware udev para uso sin sudo en la sesión diaria.

---

<a id="ejecucion"></a>
## 🖥️ Cómo Ejecutar la Aplicación

* **Desde el menú de Ubuntu:** Busca **Thunderobot Control Center**.
* **Desde la terminal:**
  ```bash
  thunderobot-control-center
  ```

---

<a id="servicio"></a>
## 🔧 Gestión del Servicio en Segundo Plano

El demonio de hardware opera de forma silenciosa en tu sesión de usuario mediante `systemd`:
```bash
# Ver estado del motor
systemctl --user status thunderobot.service

# Reiniciar motor
systemctl --user restart thunderobot.service

# Ver logs en vivo
journalctl --user -u thunderobot.service -f
```

---

<a id="desinstalacion"></a>
## 🗑️ Desinstalación

Para eliminar completamente la aplicación del sistema:
```bash
./uninstall.sh
```

---

<a id="desarrollo"></a>
## 💻 Desarrollo Local (Dev Mode)

Si deseas modificar el código o contribuir:

1. **Iniciar el motor de hardware en terminal:**
   ```bash
   python3 thunderobot_controller.py
   ```
2. **Iniciar la aplicación Flutter en modo depuración:**
   ```bash
   cd thunderobot_app
   flutter run -d linux
   ```

---

<a id="licencia"></a>
## 📄 Licencia

Este proyecto está distribuido bajo la licencia de código abierto **MIT**. Consulta el archivo [LICENSE](LICENSE) para conocer los términos completos de uso, modificación y distribución.
