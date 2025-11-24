import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/camera_wifi_screen.dart';
import 'services/rover_service.dart';
import 'services/bluetooth_camera_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoverApp());
}

class RoverApp extends StatelessWidget {
  const RoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF4A6BFF), // Modern blue primary
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoverService()),
        ChangeNotifierProvider(create: (_) => BluetoothCameraService()),
      ],
      child: MaterialApp(
        title: 'NexSoil',
        theme: baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A6BFF),
            brightness: Brightness.light,
            primary: const Color(0xFF4A6BFF),
            secondary: const Color(0xFF6C5CE7),
            surface: Colors.white,
            background: const Color(0xFFF8F9FF),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF1E293B),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200, width: 1.0),
            ),
            margin: const EdgeInsets.all(8.0),
            clipBehavior: Clip.antiAlias,
          ),
          textTheme: GoogleFonts.interTextTheme(
            baseTheme.textTheme.copyWith(
              titleLarge: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
              bodyLarge: TextStyle(color: Colors.grey.shade700, fontSize: 16),
            ),
          ),
        ),
        home: const CameraWifiScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
