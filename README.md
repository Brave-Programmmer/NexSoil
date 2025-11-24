# NexSoil — A multi-purpose Rover

A modular rover ecosystem designed for IoT automation, agriculture monitoring, robotics experimentation, and remote vehicle control, powered by ESP32-CAM / ESP8266 microcontrollers and a Flutter-based controller app.

Supports Bluetooth Classic (SPP) and Wi-Fi AP control with live telemetry, live camera feed, and digital motor control

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.9.2-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://www.android.com)

---

## 📋 Table of Contents

- [Features](#-features)
- [Repository Structure](#-repository-structure)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Usage Guide](#-usage-guide)
- [Firmware](#-firmware)
- [Protocol Reference](#-protocol-reference)
- [Wiring Diagrams](#-wiring-diagrams)
- [HTTP API Examples](#-http-api-examples)
- [Troubleshooting](#-troubleshooting)
---

## ✨ Features

- **Dual connectivity**: Bluetooth Classic (SPP) or Wi-Fi AP (HTTP control)
- **Joystick control**: Smooth analog control with deadzone and throttling
- **Real-time telemetry**: Temperature, humidity, soil moisture.
- **Camera streaming**: Bluetooth frame streaming
- **Manual controls**: Quick-access buttons for basic movements
---

## 📁 Repository Structure
```txt
├── nexsoil
│
│── rover_controller/                      # Flutter App
│   ├── lib/
│   │   ├── main.dart                      # App entry point
│   │   ├── screens/                       # All UI screens
│   │   │   ├── control_screen.dart        # Main rover control panel
│   │   │   ├── camera_screen.dart         # Live camera view + Wi-Fi
│   │   │   └── telemetry_screen.dart      # Soil, temp, humidity dashboard
│   │   ├── widgets/                       # Shared UI components
│   │   │   ├── joystick.dart              # Virtual joystick UI
│   │   │   ├── device_selection_dialog.dart # Bluetooth device picker
│   │   │   └── camera_view.dart           # RTSP/JPEG streaming viewer
│   │   └── services/                      # Core logic & integrations
│   │       ├── bluetooth_service.dart     # Bluetooth control + data TX/RX
│   │       ├── rover_service.dart         # Rover control & state handling
│   │       └── bluetooth_camera_service.dart # Bluetooth camera streaming logic
│   ├── android/                           # Android-specific platform files
│   └── pubspec.yaml                       # Flutter dependencies list
│
│── esp12ecode/                            # ESP8266 rover firmware
│   └── esp12ecode.ino
│
└── esp32code/                             # ESP32-CAM firmware
    └── esp32code.ino


---

## 🔧 Requirements

### Software

- **Flutter SDK**: ≥ 3.9.2
- **Dart SDK**: ≥ 2.19.0
- **Android Studio** or **VS Code** with Flutter extensions

### Hardware

- Android device with **Bluetooth Classic** support
- ESP8266 (ESP-12) or ESP32-CAM module
- L298N motor driver (for ESP8266 build)
- DHT11 sensor and soil moisture sensor (optional)

### Key Dependencies

- `flutter_bluetooth_serial` — Bluetooth SPP communication
- `permission_handler` — Runtime permissions
- `shared_preferences` — Settings persistence
- `provider` — State management
- `http` — HTTP control for Wi-Fi mode

---

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd nexsoil
flutter pub get
```

### 2. Configure Android Permissions

The app automatically requests required permissions at runtime:

- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (Android 12+)
- `BLUETOOTH` / `BLUETOOTH_ADMIN` (Android < 12)
- `ACCESS_FINE_LOCATION` (required for Bluetooth scanning)

### 3. Run the App

```bash
# List available devices
flutter devices

# Run on connected device
flutter run -d <device-id>

# Or run in release mode for better performance
flutter run --release -d <device-id>
```

> **Note**: Bluetooth Classic requires a physical Android device. Emulators typically don't support Bluetooth hardware.

---

## 📱 Usage Guide

### First Connection

1. **Launch the app** — Opens to Camera/WiFi screen
2. **Navigate to Control screen** — Use bottom navigation
3. **Tap "Scan & Connect"** — Opens device selection dialog
4. **Select your rover** — From bonded or discovered devices
5. **Grant permissions** — Allow Bluetooth and Location when prompted

### Reconnection

- **Quick reconnect**: Tap "Reconnect to \<device\>" button (appears after first connection)
- **Manual reconnect**: Use "Scan & Connect" to choose device again

### Joystick Control

The joystick sends commands in the format:

```
JOYSTICK x=<0-1023> y=<0-1023>
```

- **Center position**: x=512, y=512 (STOP)
- **Forward**: y > 512
- **Backward**: y < 512
- **Left/Right**: x < 512 / x > 512
- **Deadzone**: Small movements near center are ignored
- **Auto-stop**: Releases automatically send center position

### Manual Drive Buttons

Quick-access buttons for basic movements:

- `FORWARD`, `BACKWARD`, `LEFT`, `RIGHT`, `STOP`
- `TURBO ON/OFF` — Toggle high-speed mode

### Telemetry

Real-time sensor data displays in the Rover Status card:

- Temperature (°C)
- Humidity (%)
- Soil moisture (%)
- Battery voltage (V)
- Uptime (seconds)

---

## 🤖 Firmware

### ESP8266 (ESP-12) — WiFi AP Mode

**File**: `esp12ecode/esp12ecode.ino`

**Features**:

- Creates WiFi Access Point (`NexSoil_Rover`)
- HTTP server on port 80
- Motor control via L298N driver
- DHT11 temperature/humidity sensor
- Analog soil moisture sensor

**Default Credentials**:

```
SSID: NexSoil_Rover
Password: 12345678
IP: 192.168.4.1
```

**Endpoints**:

- `GET /` — Web control interface
- `GET /control?cmd=<COMMAND>` — Send drive command
- `GET /status` — JSON telemetry

**Pin Configuration**:
| Component | Pin | GPIO |
|-----------|-----|------|
| DHT11 Data | D4 | GPIO2 |
| Soil Sensor | A0 | Analog |
| Left Motor IN1 | D1 | GPIO5 |
| Left Motor IN2 | D2 | GPIO4 |
| Left Motor ENA | D5 | GPIO14 (PWM) |
| Right Motor IN3 | D6 | GPIO12 |
| Right Motor IN4 | D7 | GPIO13 |
| Right Motor ENB | D0 | GPIO16 |

**Flashing**:

```bash
# Using esptool.py
python -m esptool --port COM3 erase_flash
python -m esptool --port COM3 --baud 115200 write_flash 0x00000 esp12ecode.bin

# Or use Arduino IDE with ESP8266 board support
```

### ESP32-CAM — Bluetooth SPP Mode

**File**: `esp32code/esp32code.ino`

**Features**:

- Bluetooth Serial (SPP) communication
- JPEG camera frame streaming
- Onboard LED control
- Low-power camera configuration

**Stream Protocol**:

```
FRAME_START:<byte_length>
<raw JPEG bytes>
FRAME_END
```

**Commands**:

- `LED_ON` / `LED_OFF` — Control flash LED
- Responds with acknowledgment messages

**Pin Configuration** (AI-Thinker):
| Function | GPIO |
|----------|------|
| Camera PWDN | 32 |
| XCLK | 0 |
| SIOD (SDA) | 26 |
| SIOC (SCL) | 27 |
| Y9-Y2 | 35,34,39,36,21,19,18,5 |
| VSYNC | 25 |
| HREF | 23 |
| PCLK | 22 |
| Flash LED | 4 |

**Flashing**:

1. Connect FTDI adapter (RX→U0T, TX→U0R, GND→GND, 5V→5V)
2. Hold GPIO0 to GND while resetting/powering
3. Upload via Arduino IDE (ESP32 board support required)
4. Remove GPIO0 connection and reset

```bash
# Or using esptool.py
python -m esptool --chip esp32 --port COM3 --baud 460800 write_flash -z 0x1000 esp32code.bin
```

---

## 📡 Protocol Reference

### Joystick Commands

```
JOYSTICK x=<0-1023> y=<0-1023>
```

- Values: 0-1023 (10-bit analog range)
- Center: 512 (neutral/stop position)
- Sent continuously during joystick movement

### Drive Commands (HTTP)

```
FORWARD, BACKWARD, LEFT, RIGHT, STOP
```

Used by ESP8266 HTTP endpoints

### System Commands

```
TURBO on|off          # Toggle high-speed mode
TELEMETRY on interval=3000  # Enable periodic telemetry
TELEMETRY off         # Disable telemetry
PING                  # Connection health check (expects "OK ROVER Vx.y")
```

### Telemetry JSON Schema

```json
{
  "temp": 23.4, // Temperature (°C)
  "hum": 45.0, // Humidity (%)
  "soil": 33, // Soil moisture (%)
  "battery": 3.95, // Battery voltage (V)
  "uptime": 12345 // Uptime (seconds)
}
```

> **Note**: Telemetry lines must be terminated with `\n` (LF)

---

## 🔌 Wiring Diagrams

### ESP8266 + L298N Motor Driver

```
ESP8266 (ESP-12)          L298N Driver          Motors/Sensors
─────────────────         ──────────────         ──────────────
GPIO5 (D1)  ────────────→ IN1 (Left)
GPIO4 (D2)  ────────────→ IN2 (Left)
GPIO14 (D5) ────────────→ ENA (Left PWM)
GPIO12 (D6) ────────────→ IN3 (Right)
GPIO13 (D7) ────────────→ IN4 (Right)
GPIO16 (D0) ────────────→ ENB (Right)
GPIO2 (D4)  ────────────→ DHT11 Data Pin
A0          ────────────→ Soil Sensor Analog Out

Power Connections:
Battery (+) ────────────→ L298N VMS (Motor Supply)
Battery (-) ────────────→ L298N GND
ESP8266 3.3V ───────────→ Regulated 3.3V Supply
Common GND  ────────────→ All GND pins connected
```

**Important Notes**:

- Always share common ground between ESP8266, L298N, and sensors
- Power motors from battery (6-12V), NOT from ESP8266's 3.3V
- GPIO16 (D0) has limited PWM capability on some ESP8266 boards
- Add decoupling capacitors (100µF) across motor terminals

### ESP32-CAM Module

```
ESP32-CAM (AI-Thinker)    FTDI Adapter          Power
──────────────────────    ────────────          ─────
5V    ──────────────────→ 5V (or external)
GND   ──────────────────→ GND (common)
U0R (GPIO3) ────────────→ TX
U0T (GPIO1) ────────────→ RX
GPIO0 ──────────────────→ GND (flash mode only)
GPIO4 ──────────────────→ Flash LED

Camera pins are pre-wired internally on the module
```

**Power Requirements**:

- Use stable 5V supply capable of 1-2A
- Avoid weak USB ports (can cause brownouts)
- Camera operation is power-intensive

---

## 🌐 HTTP API Examples

When connected to ESP8266 WiFi AP (`192.168.4.1`):

### Get Status

```bash
curl http://192.168.4.1/status

# Response:
# {"temp":23.4,"hum":45.0,"soil":33}
```

### Send Drive Commands

```bash
# Move forward
curl "http://192.168.4.1/control?cmd=FORWARD"

# Turn left
curl "http://192.168.4.1/control?cmd=LEFT"

# Stop
curl "http://192.168.4.1/control?cmd=STOP"
```

### Web Interface

Open browser to `http://192.168.4.1/` for manual control page

---

## 🐛 Troubleshooting

### Bluetooth Issues

**"Bluetooth is not enabled"**

- Enable Bluetooth in Android settings
- Grant all requested permissions (Bluetooth, Location)

**No devices found during scan**

- Ensure rover is powered and within range (< 10m)
- Try pairing manually in Android Settings → Bluetooth
- Restart both devices

**Connection drops frequently**

- Check distance (Bluetooth range ~10m)
- Verify power supply to ESP module is stable
- Disable battery-saving modes for the app

### Android 12+ Permissions

If scanning fails:

1. Go to Settings → Apps → NexSoil
2. Check Permissions:
   - ✅ Nearby devices (Bluetooth)
   - ✅ Location
3. Clear app storage/cache if needed
4. Re-scan for devices

### Joystick Issues

**Jittery movement**

- Check Bluetooth signal strength
- Increase deadzone in `joystick.dart` (default: 50)
- Verify firmware is not blocking/busy

**Doesn't respond**

- Check connection status indicator
- Send manual STOP command
- Reconnect to rover

### Telemetry Issues

**JSON parsing errors**

- Firmware must send complete JSON on single line
- Each line must end with `\n` (LF character)
- Check serial monitor output from firmware

**Missing sensor data**

- Verify sensor wiring matches pin configuration
- Check DHT11 library is installed in Arduino IDE
- Test sensors independently with example sketches

### WiFi AP Issues

**Cannot connect to rover AP**

- Check SSID name matches firmware (`NexSoil_Rover`)
- Verify password (default: `12345678`)
- Disable mobile data while connected to rover WiFi
- Some phones require "Connect anyway" for networks without internet

**HTTP commands fail**

- Verify IP address is `192.168.4.1`
- Check rover's web server is running (LED indicators)
- Try accessing `http://192.168.4.1/` in browser first

---

## 👨‍💻 Development

### Running Development Build

```bash
# Debug mode with hot reload
flutter run -d <device-id>

# Profile mode (performance testing)
flutter run --profile -d <device-id>

# Release mode (production)
flutter run --release -d <device-id>
```

### Code Quality

```bash
# Static analysis
flutter analyze

# Format code
flutter format lib/

# Run tests (when available)
flutter test
```

### Key Files to Modify

| File                                  | Purpose                              |
| ------------------------------------- | ------------------------------------ |
| `lib/services/bluetooth_service.dart` | Connection, HTTP, telemetry handling |
| `lib/widgets/joystick.dart`           | Joystick behavior, mapping, deadzone |
| `lib/screens/control_screen.dart`     | Main UI layout and controls          |
| `lib/services/rover_service.dart`     | Rover state management               |

### Architecture Notes

- **State Management**: Provider pattern
- **Communication**: Bidirectional (commands out, telemetry in)
- **Reconnection**: Exponential backoff with max attempts
- **Watchdog**: 10-second PING interval checks connection health
- **Persistence**: SharedPreferences for last device and settings

---

## 🔐 Security Notes

⚠️ **Important**: These examples are for development/prototyping

- **WiFi AP password**: Change default `12345678` in firmware
- **HTTP endpoints**: No authentication — add token or basic auth for production
- **Bluetooth pairing**: Uses standard Android pairing (PIN if required)

---
