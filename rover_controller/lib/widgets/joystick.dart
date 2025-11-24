import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

typedef JoystickCommandCallback = void Function(String command, int speed);

class Joystick extends StatefulWidget {
  final double size;
  final JoystickCommandCallback? onCommand;

  const Joystick({super.key, this.size = 200, this.onCommand});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick>
    with SingleTickerProviderStateMixin {
  Offset _knob = Offset.zero;
  Timer? _repeatTimer;
  String _lastCommand = 'S';
  int _lastX = 512;
  int _lastY = 512;

  static const _throttleMs = 100;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  late AnimationController _animController;
  late Animation<Offset> _animKnob;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animKnob = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.addListener(() => setState(() => _knob = _animKnob.value));
  }

  void _startRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _reportMovement();
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _setKnobFromLocal(Offset local) {
    final center = widget.size / 2;
    final off = local - Offset(center, center);
    final radius = widget.size / 2 - 10;
    final dist = off.distance;
    final clamped = dist > radius ? off / dist * radius : off;
    setState(() => _knob = clamped);
  }

  void _resetKnob() {
    _animKnob = Tween<Offset>(begin: _knob, end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward(from: 0);
    widget.onCommand?.call('JOYSTICK x=512 y=512', 0);
  }

  void _reportMovement() {
    final now = DateTime.now();
    if (now.difference(_lastSent).inMilliseconds < _throttleMs) return;
    _lastSent = now;

    final size = widget.size;
    final xNorm = (_knob.dx / (size / 2)).clamp(-1.0, 1.0);
    final yNorm = -(_knob.dy / (size / 2)).clamp(-1.0, 1.0);

    const deadzone = 0.08;
    final x = xNorm.abs() < deadzone ? 0.0 : xNorm;
    final y = yNorm.abs() < deadzone ? 0.0 : yNorm;

    final magnitude = math.sqrt(x * x + y * y).clamp(0.0, 1.0);

    final xMapped = ((x + 1.0) * 511.5).round();
    final yMapped = ((y + 1.0) * 511.5).round();
    int speed = (magnitude * 255).round();

    String currentMovement = '';
    if (x.abs() < 0.2 && y.abs() < 0.2) {
      currentMovement = 'Stop';
      speed = 0;
    } else if (x.abs() < 0.3 && y > 0.7) {
      currentMovement = 'Forward';
      speed = 255;
    } else if (x.abs() < 0.3 && y < -0.7) {
      currentMovement = 'Backward';
      speed = 255;
    } else if (x.abs() > 0.7 && y.abs() < 0.3) {
      currentMovement = x > 0 ? 'Pivot Right' : 'Pivot Left';
      speed = 180;
    } else if (y > 0) {
      if (x > 0.3) {
        currentMovement = 'Right Curve Forward';
        speed = (speed * 0.8).round();
      } else if (x < -0.3) {
        currentMovement = 'Left Curve Forward';
        speed = (speed * 0.8).round();
      } else {
        currentMovement = 'Forward';
      }
    } else if (y < 0) {
      if (x > 0.3) {
        currentMovement = 'Right Curve Backward';
        speed = (speed * 0.8).round();
      } else if (x < -0.3) {
        currentMovement = 'Left Curve Backward';
        speed = (speed * 0.8).round();
      } else {
        currentMovement = 'Backward';
      }
    }

    if ((xMapped - _lastX).abs() > 20 ||
        (yMapped - _lastY).abs() > 20 ||
        currentMovement != _lastCommand) {
      _lastX = xMapped;
      _lastY = yMapped;
      _lastCommand = currentMovement;
      final command = 'JOYSTICK x=$xMapped y=$yMapped';
      widget.onCommand?.call(command, speed);
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final knobRadius = math.max(18.0, size * 0.12);
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        gradient: RadialGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade300],
          center: Alignment.topLeft,
          radius: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(3, 3),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-3, -3),
          ),
        ],
      ),
      child: GestureDetector(
        onPanStart: (e) {
          _setKnobFromLocal(e.localPosition);
          _reportMovement();
          _startRepeat();
        },
        onPanUpdate: (e) {
          _setKnobFromLocal(e.localPosition);
        },
        onPanEnd: (_) {
          _stopRepeat();
          _resetKnob();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(size, size), painter: _JoystickPainter()),
            ..._directionIndicators(size),
            Transform.translate(
              offset: _knob,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: knobRadius * 2,
                height: knobRadius * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.95),
                      theme.colorScheme.primary.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _directionIndicators(double size) {
    const double arrowSize = 18;
    final arrows = <Widget>[];
    const dirs = [
      (Icons.keyboard_arrow_up, Alignment.topCenter),
      (Icons.keyboard_arrow_down, Alignment.bottomCenter),
      (Icons.keyboard_arrow_left, Alignment.centerLeft),
      (Icons.keyboard_arrow_right, Alignment.centerRight),
    ];
    for (var (icon, align) in dirs) {
      arrows.add(
        Align(
          alignment: align,
          child: Icon(icon, color: Colors.grey.shade400, size: arrowSize),
        ),
      );
    }
    return arrows;
  }
}

class _JoystickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Glass-like background
    final bg = Paint()
      ..shader = RadialGradient(
        colors: [Colors.grey.shade100, Colors.grey.shade400.withOpacity(0.9)],
        center: Alignment.topLeft,
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bg);

    final ring = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, ring);

    final cross = Paint()
      ..color = Colors.grey.shade500.withOpacity(0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      cross,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), cross);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
