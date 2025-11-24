import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'telemetry_data.dart';

class RoverService extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.4.1'; // No trailing slash
  static const int _timeoutSeconds = 3; // Reduced timeout for better UX

  final http.Client _client = http.Client();
  bool _isConnected = false;
  DateTime? _lastErrorTime;
  static const Duration _errorCooldown = Duration(seconds: 5);

  RoverTelemetry? _lastTelemetry;
  RoverTelemetry? get lastTelemetry => _lastTelemetry;

  Timer? _telemetryTimer;

  bool get isConnected => _isConnected;

  set isConnected(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      notifyListeners();
    }
  }

  /// Get the video stream URL
  /// This URL can be used with a video player widget that supports MJPEG streams
  String get videoStreamUrl => _buildUrl('stream').toString();

  /// Check if the video stream is available
  Future<bool> isStreamAvailable() async {
    try {
      final response = await _client
          .head(_buildUrl('stream'))
          .timeout(const Duration(seconds: _timeoutSeconds));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking stream availability: $e');
      return false;
    }
  }

  // Helper to ensure URLs are properly formatted
  Uri _buildUrl(String path) {
    // Remove any leading slashes from path to prevent double slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl/$cleanPath');
  }

  // Skip connection check but keep the method for API compatibility
  Future<bool> checkConnection() async {
    isConnected = true; // This will now work with the setter
    return true;
  }

  Future<void> sendCommand(String command, [int? speed]) async {
    // Skip if we're in error cooldown
    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!) < _errorCooldown) {
      return;
    }

    try {
      String url;
      if (command.startsWith('JOYSTICK')) {
        // For joystick commands, include the x, y values in the URL
        url = _buildUrl('control?$command').toString();
      } else {
        // For regular commands, use the command parameter
        url = _buildUrl(
          'control?cmd=$command${speed != null ? '&speed=$speed' : ''}',
        ).toString();
      }

      final response = await _client
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: _timeoutSeconds),
            onTimeout: () => http.Response('Request Timeout', 408),
          );

      if (response.statusCode != 200) {
        _handleError(
          'Command "$command" failed with status: ${response.statusCode}',
        );
      } else {
        // Reset error state on successful command
        _lastErrorTime = null;
      }
    } on SocketException catch (e) {
      _handleError('Network error: ${e.message}');
      rethrow;
    } on TimeoutException {
      _handleError('Command "$command" timed out');
      rethrow;
    } catch (e) {
      _handleError('Error sending command "$command": $e');
      rethrow;
    }
  }

  /// Fetch telemetry via HTTP GET /data and parse flexible JSON formats.
  Future<RoverTelemetry?> fetchTelemetry() async {
    try {
      final response = await _client
          .get(_buildUrl('status'))
          .timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final parsed = RoverTelemetry.tryParse(response.body);
        if (parsed != null) {
          _lastTelemetry = parsed;
          notifyListeners();
        }
        return parsed;
      } else {
        debugPrint('Telemetry fetch failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching telemetry: $e');
      return null;
    }
  }

  /// Start periodic telemetry polling (interval in seconds).
  void startTelemetryPolling({int intervalSeconds = 3}) {
    stopTelemetryPolling();
    _telemetryTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      fetchTelemetry();
    });
  }

  void stopTelemetryPolling() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
  }

  void _handleError(String message) {
    debugPrint(message);
    _lastErrorTime = DateTime.now();
    // Optionally notify listeners about the error
    // notifyListeners();
  }

  @override
  void dispose() {
    try {
      _client.close();
    } catch (e) {
      debugPrint('Error disposing HTTP client: $e');
    }
    super.dispose();
  }
}

class RoverCommands {
  // Movement commands
  static const String forward = 'FORWARD';
  static const String backward = 'BACKWARD';
  static const String left = 'LEFT';
  static const String right = 'RIGHT';
  static const String stop = 'STOP';

  // Joystick command prefix
  static const String joystick = 'JOYSTICK';

  // Status commands
  static const String getStatus = 'STATUS';
  static const String getBattery = 'BATTERY';

  // Speed constants
  static const int minSpeed = 0;
  static const int maxSpeed = 255;
}
