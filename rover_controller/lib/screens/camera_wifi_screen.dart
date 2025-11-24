import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/rover_service.dart';
import '../services/bluetooth_camera_service.dart';
import '../widgets/rover_control_panel.dart';

class CameraWifiScreen extends StatefulWidget {
  const CameraWifiScreen({super.key});

  @override
  State<CameraWifiScreen> createState() => _CameraWifiScreenState();
}

class _CameraWifiScreenState extends State<CameraWifiScreen> {
  @override
  void initState() {
    super.initState();
    // Nothing heavy at start; user triggers connections
  }

  // Build connection status indicator for the app bar
  Widget _buildConnectionStatus(
    BuildContext context, {
    required IconData icon,
    required bool isConnected,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isConnected ? Colors.green : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isConnected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Build a connection button with loading state
  Widget _buildConnectionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isActive,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                icon,
                size: 16,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isActive
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          foregroundColor: isActive
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          animationDuration: const Duration(milliseconds: 200),
          enableFeedback: true,
        ),
      ),
    );
  }

  // Build an action button with custom styling
  // Build a connection card with icon, status, and action button
  Widget _buildConnectionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isConnected,
    required VoidCallback? onPressed,
    required Color activeColor,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected
              ? activeColor.withOpacity(0.2)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? activeColor.withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isConnected ? activeColor : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Label
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Status Text
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isConnected ? Colors.green : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Connect Button
              Container(
                height: 32,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isConnected
                      ? Colors.green.withOpacity(0.1)
                      : activeColor,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onPressed,
                    child: Center(
                      child: Text(
                        isConnected ? 'Connected' : 'Connect',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: isConnected ? Colors.green : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roverService = Provider.of<RoverService>(context);
    final btService = Provider.of<BluetoothCameraService>(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return DefaultTabController(
      length: 3, // Increased to 3 for the new Camera tab
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'NexSoil',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          bottom: TabBar(
            isScrollable: true, // Allow tabs to scroll if needed
            tabs: const [
              Tab(icon: Icon(Icons.videocam), text: 'Camera'),
              Tab(icon: Icon(Icons.directions_car), text: 'Controls'),
              Tab(icon: Icon(Icons.sensors), text: 'Sensor Data'),
            ],
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
          ),
          actions: [
            _buildConnectionStatus(
              context,
              icon: Icons.bluetooth,
              isConnected: btService.isConnected,
              label: 'Bluetooth',
            ),
            const SizedBox(width: 8),
            _buildConnectionStatus(
              context,
              icon: Icons.wifi,
              isConnected: roverService.isConnected,
              label: 'Wi-Fi',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: TabBarView(
          children: [
            // Camera Tab
            Column(
              children: [
                // Camera Preview Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Camera Feed',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildActionButton(
                                            context: context,
                                            onPressed: btService.isConnected
                                                ? () => btService
                                                      .startCameraStream()
                                                : null,
                                            icon: Icons.play_arrow,
                                            label: 'Start Stream',
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                          _buildActionButton(
                                            context: context,
                                            onPressed: btService.isConnected
                                                ? () => btService
                                                      .stopCameraStream()
                                                : null,
                                            icon: Icons.stop,
                                            label: 'Stop',
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                          0.6,
                                      minHeight: 200,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: theme.dividerColor
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: ValueListenableBuilder<Uint8List?>(
                                            valueListenable:
                                                btService.latestFrame,
                                            builder: (context, bytes, _) {
                                              if (bytes == null) {
                                                return Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.videocam_off,
                                                        size: 48,
                                                        color: theme.hintColor,
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        'No camera feed available',
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: theme
                                                                  .hintColor,
                                                            ),
                                                      ),
                                                      if (!btService
                                                          .isConnected)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8.0,
                                                              ),
                                                          child: Text(
                                                            'Connect to a device to start streaming',
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: theme
                                                                      .hintColor,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return Image.memory(
                                                bytes,
                                                gaplessPlayback: true,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                height: double.infinity,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Controls Tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Connection Status Section
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              'CONNECTION STATUS',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),

                          // Connection Cards
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                // Bluetooth Card
                                Expanded(
                                  child: _buildConnectionCard(
                                    context,
                                    icon: Icons.bluetooth,
                                    label: 'Bluetooth',
                                    isConnected: btService.isConnected,
                                    onPressed: btService.isConnected
                                        ? null
                                        : () => btService.startScanAndConnect(),
                                    activeColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Wi-Fi Card
                                Expanded(
                                  child: _buildConnectionCard(
                                    context,
                                    icon: Icons.wifi,
                                    label: 'Wi-Fi',
                                    isConnected: roverService.isConnected,
                                    onPressed: roverService.isConnected
                                        ? null
                                        : () async {
                                            final ok = await roverService
                                                .checkConnection();
                                            if (ok)
                                              roverService
                                                  .startTelemetryPolling();
                                          },
                                    activeColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rover Controls Section
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              'ROVER CONTROLS',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),

                          // Controls Panel
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: RoverControlPanel(
                              showJoystick: isWideScreen,
                              buttonSize: isWideScreen ? 80 : 60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sensor Data Tab
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<RoverService>(
                    context,
                    listen: false,
                  ).fetchTelemetry();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with last updated time
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SENSOR READINGS',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.update,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sensor Grid
                      if (roverService.lastTelemetry == null)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sensors_off_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No sensor data available',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => Provider.of<RoverService>(
                                  context,
                                  listen: false,
                                ).fetchTelemetry(),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _TelemetryView(telemetry: roverService.lastTelemetry!),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryView extends StatelessWidget {
  final dynamic telemetry;

  const _TelemetryView({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final temp =
        telemetry.temperature?.toDouble() ?? telemetry['temp']?.toDouble();
    final humidity =
        telemetry.humidity?.toDouble() ?? telemetry['hum']?.toDouble();
    final soilMoisture =
        telemetry.soilMoisture?.toDouble() ?? telemetry['soil']?.toDouble();

    return Column(
      children: [
        // Temperature Card
        _buildSensorCard(
          context,
          title: 'Temperature',
          value: temp,
          unit: '°C',
          icon: Icons.thermostat,
          color: const Color(0xFFFF7043), // Deep Orange
        ),

        // Humidity Card
        _buildSensorCard(
          context,
          title: 'Air Humidity',
          value: humidity,
          unit: '%',
          icon: Icons.water_drop,
          color: const Color(0xFF42A5F5), // Blue
        ),

        // Soil Moisture Card
        _buildSensorCard(
          context,
          title: 'Soil Moisture',
          value: soilMoisture,
          unit: '%',
          icon: Icons.grass,
          color: const Color(0xFF66BB6A), // Green
        ),

        // Last Update & Refresh
        const SizedBox(height: 8),
        Row(
          children: [
            const Spacer(),
            TextButton.icon(
              onPressed: () => Provider.of<RoverService>(
                context,
                listen: false,
              ).fetchTelemetry(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh Data'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                textStyle: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    BuildContext context, {
    required String title,
    required double? value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final displayValue = value?.toStringAsFixed(1) ?? '--';
    final progressValue = value != null ? (value / 100).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icon with background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),

            // Sensor data
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Value with unit
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: displayValue,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontSize: 24,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: unit,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        color.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            if (value != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(value, title).withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(value, title).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(double value, String title) {
    if (title.toLowerCase().contains('temp')) {
      return value > 30
          ? Colors.red
          : (value < 15 ? Colors.blue : Colors.green);
    } else if (title.toLowerCase().contains('moisture') ||
        title.toLowerCase().contains('humidity')) {
      return value < 30
          ? Colors.red
          : (value > 80 ? Colors.blue : Colors.green);
    }
    return Colors.green;
  }
}
