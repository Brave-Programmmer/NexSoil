import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_camera_service.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late BluetoothCameraService _cameraService;
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isLedOn = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cameraService = context.read<BluetoothCameraService>();
    _checkConnection();
    _cameraService.addListener(_onCameraServiceUpdate);
  }

  void _onCameraServiceUpdate() {
    if (mounted) {
      setState(() {
        _isConnected = _cameraService.isConnected;
        _isLoading = _cameraService.connectionStatus == ConnectionStatus.connecting;
        
        if (_cameraService.connectionStatus == ConnectionStatus.error) {
          _errorMessage = 'Connection error';
        } else {
          _errorMessage = null;
        }
      });
    }
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
    });
    
    if (!_cameraService.isConnected) {
      await _cameraService.startScanAndConnect();
    }
    
    if (mounted) {
      setState(() {
        _isConnected = _cameraService.isConnected;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraService.removeListener(_onCameraServiceUpdate);
    super.dispose();
  }

  Future<void> _startCameraStream() async {
    if (_cameraService.isConnected) {
      await _cameraService.startCameraStream();
    } else {
      await _checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with controls
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.videocam, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Camera View',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: _isConnected ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected ? 'Connected' : 'Disconnected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _isConnected ? Colors.green : Colors.grey,
                          ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _isConnected ? _startCameraStream : null,
                      tooltip: 'Refresh camera',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (_isConnected) _buildLedControls(),
              ],
            ),
          ),
          // Camera display area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _buildCameraContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedControls() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),  
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('LED: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ToggleButtons(
            isSelected: [_isLedOn, !_isLedOn],
            onPressed: (int index) {
              setState(() {
                _isLedOn = index == 0;
                if (_isLedOn) {
                  _cameraService.turnOnLed();
                } else {
                  _cameraService.turnOffLed();
                }
              });
            },
            borderRadius: BorderRadius.circular(4),
            selectedColor: Colors.white,
            fillColor: Colors.blue,
            color: Colors.blue,
            selectedBorderColor: Colors.blue[700],
            borderColor: Colors.grey[400],
            constraints: const BoxConstraints(
              minWidth: 60,
              minHeight: 30,
            ),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_on, size: 16),
                    SizedBox(width: 4),
                    Text('ON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flash_off, size: 16),
                    SizedBox(width: 4),
                    Text('OFF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _checkConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Bluetooth Disconnected', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text(
              'Connect to the rover to view camera',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _checkConnection,
              icon: const Icon(Icons.bluetooth),
              label: const Text('Connect to Rover'),
            ),
          ],
        ),
      );
    }

    // Display the camera feed
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: _cameraService.latestFrame,
      builder: (context, frame, _) {
        if (frame == null || frame.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Waiting for camera feed...'),
              ],
            ),
          );
        }

        return Image.memory(
          frame,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text('Error displaying frame'),
            );
          },
        );
      },
    );
  }
}
