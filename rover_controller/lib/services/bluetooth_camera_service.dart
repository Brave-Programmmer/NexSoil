import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class BluetoothCameraService extends ChangeNotifier {
  static const String frameStartMarker = 'FRAME_START';
  static const String frameEndMarker = 'FRAME_END';
  static const int maxFrameSize = 2 * 1024 * 1024; // 2MB limit
  static const Duration _connectionTimeout = Duration(seconds: 10);

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSub;
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySub;
  Timer? _reconnectTimer;
  Timer? _frameRateTimer;

  final List<int> _frameBuffer = [];
  bool _isReceivingFrame = false;
  int _currentFrameSize = 0;
  int _lastFrameTime = 0;
  int _frameCount = 0;

  bool _isConnecting = false;
  bool _isConnected = false;
  int _reconnectAttempts = 0;

  String? _connectedDeviceName;
  String? _connectedDeviceAddress;

  final ValueNotifier<Uint8List?> latestFrame = ValueNotifier(null);
  final ValueNotifier<double> _frameRate = ValueNotifier(0);
  final ValueNotifier<int> _frameSize = ValueNotifier(0);
  final ValueNotifier<ConnectionStatus> _connectionStatus = ValueNotifier(
    ConnectionStatus.disconnected,
  );

  // ======== Getters ========
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDeviceName;
  String? get connectedDeviceAddress => _connectedDeviceAddress;
  double get frameRate => _frameRate.value;
  int get frameSize => _frameSize.value;
  ConnectionStatus get connectionStatus => _connectionStatus.value;

  static const String cmdStartStream = 'START_CAM';
  static const String cmdStopStream = 'STOP_CAM';
  static const String cmdGetStatus = 'STATUS';
  static const String cmdLedOn = 'LED_ON';
  static const String cmdLedOff = 'LED_OFF';

  // ======== Discovery & Connect ========
  Future<void> startScanAndConnect({
    Duration scanDuration = const Duration(seconds: 10),
  }) async {
    if (_isConnecting || _isConnected) {
      debugPrint('Already connected or connecting');
      return;
    }

    _updateStatus(ConnectionStatus.connecting);
    _isConnecting = true;

    try {
      await _discoverySub?.cancel();
      bool deviceFound = false;

      final discovery = FlutterBluetoothSerial.instance.startDiscovery();
      _discoverySub = discovery.listen((result) async {
        final device = result.device;
        final name = device.name?.toLowerCase() ?? '';
        final address = device.address;

        if (name.isNotEmpty && _isCameraDevice(name)) {
          deviceFound = true;
          await _discoverySub?.cancel();
          debugPrint('📸 Found camera device: $name ($address)');
          await _connectToDevice(device);
        }
      }, onError: (error) => _handleError('Discovery error: $error'));

      await Future.delayed(scanDuration);

      if (!deviceFound && !_isConnected) {
        _handleError('No camera device found');
      }
    } catch (e) {
      _handleError('Discovery failed: $e');
    } finally {
      _isConnecting = false;
    }
  }

  bool _isCameraDevice(String name) {
    const patterns = [
      'esp32',
      'esp32-cam',
      'cam',
      'camera',
      'rover',
      'nexsoil',
      'ai-thinker',
    ];
    return patterns.any((p) => name.contains(p));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnected) {
      debugPrint('Already connected to device');
      return;
    }

    _updateStatus(ConnectionStatus.connecting);
    _isConnecting = true;

    try {
      await _cleanupConnection();
      debugPrint('🔗 Connecting to ${device.name} (${device.address})...');

      _connection = await BluetoothConnection.toAddress(
        device.address,
      ).timeout(_connectionTimeout);

      _isConnecting = false;
      _connectedDeviceName = device.name;
      _connectedDeviceAddress = device.address;
      _updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      debugPrint('✅ Connected to ${device.name}');
      _startFrameRateCalculation();

      _inputSub = _connection!.input!.listen(
        _onDataReceived,
        onError: (e) => _handleError('Connection error: $e'),
        onDone: () => _handleDisconnect(),
        cancelOnError: true,
      );

      await _sendCommand(cmdStartStream);
    } on TimeoutException {
      _handleError('Connection timeout');
    } catch (e) {
      _handleError('Connect failed: $e');
    } finally {
      _isConnecting = false;
    }
  }

  // ======== Data Processing ========
  void _onDataReceived(Uint8List data) {
    _frameBuffer.addAll(data);

    try {
      if (!_isReceivingFrame) {
        final bufferText = String.fromCharCodes(_frameBuffer);
        final startIdx = bufferText.indexOf(frameStartMarker);
        if (startIdx >= 0) {
          final headerEnd = bufferText.indexOf('\n', startIdx);
          if (headerEnd > startIdx) {
            final header = bufferText.substring(startIdx, headerEnd).trim();
            final match = RegExp(r'FRAME_START[: ]?(\d+)').firstMatch(header);
            if (match != null) {
              _currentFrameSize = int.tryParse(match.group(1) ?? '0') ?? 0;
              if (_currentFrameSize > 0 && _currentFrameSize < maxFrameSize) {
                _isReceivingFrame = true;
                final all = Uint8List.fromList(_frameBuffer);
                final offset = headerEnd + 1;
                _frameBuffer
                  ..clear()
                  ..addAll(all.sublist(offset));
              } else {
                _resetFrameBuffer();
              }
            } else {
              // malformed header
              final offset = headerEnd + 1;
              final all = Uint8List.fromList(_frameBuffer);
              _frameBuffer
                ..clear()
                ..addAll(all.sublist(offset));
            }
          }
        } else if (_frameBuffer.length > 1000) {
          _frameBuffer.clear();
        }
      }

      // if receiving frame
      if (_isReceivingFrame && _frameBuffer.length >= _currentFrameSize) {
        final endMarker = utf8.decode(
          _frameBuffer.sublist(_currentFrameSize),
          allowMalformed: true,
        );
        if (endMarker.contains(frameEndMarker)) {
          _processCompleteFrame();
        }
      }
    } catch (e) {
      _resetFrameBuffer();
    }
  }

  void _processCompleteFrame() {
    try {
      final frameData = _frameBuffer.sublist(0, _currentFrameSize);
      _frameCount++;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastFrameTime > 0) {
        final delta = now - _lastFrameTime;
        if (delta > 0) _frameRate.value = 1000 / delta;
      }
      _lastFrameTime = now;
      _frameSize.value = _currentFrameSize;

      latestFrame.value = Uint8List.fromList(frameData);

      final remaining = _frameBuffer.length > _currentFrameSize
          ? _frameBuffer.sublist(_currentFrameSize)
          : <int>[];
      _frameBuffer
        ..clear()
        ..addAll(remaining);

      _isReceivingFrame = false;
      _currentFrameSize = 0;

      if (_frameBuffer.isNotEmpty) {
        Future.microtask(
          () => _onDataReceived(Uint8List.fromList(_frameBuffer)),
        );
      }
    } catch (e) {
      _resetFrameBuffer();
    }
  }

  void _resetFrameBuffer() {
    _frameBuffer.clear();
    _isReceivingFrame = false;
    _currentFrameSize = 0;
  }

  // ======== Commands ========
  Future<bool> _sendCommand(String cmd) async {
    if (_connection == null || !_isConnected) return false;
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$cmd\n')));
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      _handleError('Command send failed: $e');
      return false;
    }
  }

  Future<void> startCameraStream() async => _sendCommand(cmdStartStream);
  Future<void> stopCameraStream() async => _sendCommand(cmdStopStream);
  
  /// Turns ON the onboard LED (GPIO 4) - acts as flash light
  Future<bool> turnOnLed() async => _sendCommand(cmdLedOn);
  
  /// Turns OFF the onboard LED (GPIO 4)
  Future<bool> turnOffLed() async => _sendCommand(cmdLedOff);

  // ======== Utilities ========
  void _startFrameRateCalculation() {
    _frameRateTimer?.cancel();
    _frameRateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _frameRate.value = _frameCount.toDouble();
      _frameCount = 0;
    });
  }

  void _updateStatus(ConnectionStatus status) {
    _connectionStatus.value = status;
    _isConnected = status == ConnectionStatus.connected;
    notifyListeners();
  }

  void _handleDisconnect() {
    debugPrint('🔌 Connection closed');
    _cleanupConnection();
    _updateStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _handleError(String msg) {
    debugPrint('⚠️ $msg');
    _cleanupConnection();
    _updateStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  // ======== Reconnect Logic ========
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    _updateStatus(ConnectionStatus.reconnecting);
    _reconnectAttempts++;
    final delay = Duration(seconds: 3 * _reconnectAttempts.clamp(1, 5));

    _reconnectTimer = Timer(delay, () async {
      if (_connectedDeviceAddress != null) {
        final device = BluetoothDevice(
          address: _connectedDeviceAddress!,
          name: _connectedDeviceName,
          type: BluetoothDeviceType.unknown,
          bondState: BluetoothBondState.bonded,
        );
        await _connectToDevice(device);
      }
    });
  }

  Future<void> _cleanupConnection() async {
    _frameRateTimer?.cancel();
    _frameRateTimer = null;
    await _discoverySub?.cancel();
    await _inputSub?.cancel();
    _discoverySub = null;
    _inputSub = null;

    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;

    _isConnected = false;
    _isConnecting = false;
    latestFrame.value = null;
    _resetFrameBuffer();
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await stopCameraStream();
    await _cleanupConnection();
    _connectedDeviceAddress = null;
    _connectedDeviceName = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _frameRateTimer?.cancel();
    _discoverySub?.cancel();
    _inputSub?.cancel();
    _connection?.close();
    latestFrame.dispose();
    _frameRate.dispose();
    _frameSize.dispose();
    _connectionStatus.dispose();
    super.dispose();
  }
}
