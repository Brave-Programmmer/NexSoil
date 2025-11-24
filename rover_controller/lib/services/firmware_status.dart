import 'dart:convert';

class FirmwareStatus {
  final bool telemetryEnabled;
  final bool turboEnabled;
  final int pwmFrequency;

  const FirmwareStatus({
    required this.telemetryEnabled,
    required this.turboEnabled,
    required this.pwmFrequency,
  });

  factory FirmwareStatus.fromJson(Map<String, dynamic> json) {
    return FirmwareStatus(
      telemetryEnabled: json['telemetry'] == 1,
      turboEnabled: json['turbo'] == 1,
      pwmFrequency: json['pwm_freq'] as int,
    );
  }

  static FirmwareStatus? tryParse(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FirmwareStatus.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() =>
      'FirmwareStatus('
      'telemetry: $telemetryEnabled, '
      'turbo: $turboEnabled, '
      'pwmFreq: $pwmFrequency)';
}

// RoverTelemetry moved to services/telemetry_data.dart
