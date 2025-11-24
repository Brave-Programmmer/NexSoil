import 'dart:convert';

class RoverTelemetry {
  final double temperature;
  final double humidity;
  final int soilMoisture;
  final double batteryVoltage;
  final int? batteryPercent;

  const RoverTelemetry({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.batteryVoltage,
    this.batteryPercent,
  });

  /// Accepts flexible key names to handle different firmware responses.
  factory RoverTelemetry.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    final temp = parseDouble(json['temp'] ?? json['temperature'] ?? json['t']);
    final hum = parseDouble(json['hum'] ?? json['humidity'] ?? json['h']);
    final soil = parseInt(json['soil'] ?? json['soil_moisture'] ?? json['s']);
    final battV = parseDouble(
      json['battery_v'] ?? json['battery_voltage'] ?? json['battery'] ?? 0.0,
    );
    final battPct =
        json['battery_percent'] ??
        json['batteryPct'] ??
        json['battery_percent'];

    return RoverTelemetry(
      temperature: temp,
      humidity: hum,
      soilMoisture: soil,
      batteryVoltage: battV,
      batteryPercent: battPct == null ? null : parseInt(battPct),
    );
  }

  static RoverTelemetry? tryParse(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return RoverTelemetry.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'temp': temperature,
    'hum': humidity,
    'soil': soilMoisture,
    'battery_v': batteryVoltage,
    'battery_percent': batteryPercent,
  };

  bool get isOverheating => temperature > 60;

  @override
  String toString() =>
      'RoverTelemetry(temp: ${temperature.toStringAsFixed(1)}°C, hum: ${humidity.toStringAsFixed(1)}%, soil: $soilMoisture, battery: ${batteryVoltage.toStringAsFixed(2)}V (${batteryPercent ?? -1}%))';
}
