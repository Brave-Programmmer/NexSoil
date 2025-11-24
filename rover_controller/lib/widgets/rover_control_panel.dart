import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rover_service.dart';
import 'joystick.dart';

class RoverControlPanel extends StatelessWidget {
  final double buttonSize;
  final double iconSize;
  final bool showJoystick;

  const RoverControlPanel({
    super.key,
    this.buttonSize = 100,
    this.iconSize = 40,
    this.showJoystick = true,
  });

  @override
  Widget build(BuildContext context) {
    final roverService = Provider.of<RoverService>(context, listen: false);
    final theme = Theme.of(context);
    final activeButtonColor = theme.colorScheme.primary;
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isPortrait = screenSize.height > screenSize.width;

    // Calculate sizes based on screen dimensions
    final double maxAvailableWidth = isPortrait
        ? screenSize.width -
              padding.horizontal -
              48 // Account for padding and container padding
        : screenSize.height - padding.vertical - 48;

    final double baseButtonSize = (maxAvailableWidth * 0.24).clamp(
      50,
      80,
    ); // Reduced size range
    final double baseIconSize = baseButtonSize * 0.4;
    final double buttonSpacing = 6.0; // Reduced spacing

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showJoystick) ...[
            const Text(
              'JOYSTICK MODE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Joystick(
                size: isPortrait
                    ? screenSize.width * 0.4
                    : screenSize.height * 0.4,
                onCommand: (command, speed) {
                  roverService.sendCommand(command, speed);
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'OR',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'BUTTON CONTROLS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // =============== BUTTON CONTROLS (D-PAD) ===============
          Container(
            padding: const EdgeInsets.all(6), // Further reduced padding
            constraints: BoxConstraints(
              maxWidth:
                  baseButtonSize * 3 + buttonSpacing * 4, // Exact width needed
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Forward Button (Top)
                _ControlButton(
                  icon: Icons.arrow_upward,
                  size: baseButtonSize,
                  iconSize: baseIconSize,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  activeColor: activeButtonColor,
                  elevation: 6,
                  onPressed: () => roverService.sendCommand(
                    RoverCommands.backward,
                    RoverCommands.maxSpeed,
                  ),
                  onReleased: () =>
                      roverService.sendCommand(RoverCommands.stop),
                ),
                const SizedBox(height: 8), // Reduced spacing
                // Middle Row (Left, Stop, Right)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Left Button
                    _ControlButton(
                      icon: Icons.arrow_back,
                      size: baseButtonSize,
                      iconSize: baseIconSize,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      activeColor: activeButtonColor,
                      elevation: 6,
                      onPressed: () => roverService.sendCommand(
                        RoverCommands.left,
                        RoverCommands.maxSpeed ~/ 2,
                      ),
                      onReleased: () =>
                          roverService.sendCommand(RoverCommands.stop),
                    ),
                    SizedBox(width: buttonSpacing), // Use calculated spacing
                    // STOP Button
                    Container(
                      width:
                          baseButtonSize * 0.75, // Slightly smaller stop button
                      height: baseButtonSize * 0.75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.error,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white),
                        iconSize: baseIconSize * 0.7, // Smaller icon
                        onPressed: () =>
                            roverService.sendCommand(RoverCommands.stop),
                        style: IconButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ),
                    SizedBox(width: buttonSpacing), // Use calculated spacing
                    // Right Button
                    _ControlButton(
                      icon: Icons.arrow_forward,
                      size: baseButtonSize,
                      iconSize: baseIconSize,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      activeColor: activeButtonColor,
                      elevation: 6,
                      onPressed: () => roverService.sendCommand(
                        RoverCommands.right,
                        RoverCommands.maxSpeed ~/ 2,
                      ),
                      onReleased: () =>
                          roverService.sendCommand(RoverCommands.stop),
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced spacing
                // Backward Button (Bottom)
                _ControlButton(
                  icon: Icons.arrow_downward,
                  size: baseButtonSize,
                  iconSize: baseIconSize,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  activeColor: activeButtonColor,
                  elevation: 6,
                  onPressed: () => roverService.sendCommand(
                    RoverCommands.forward,
                    RoverCommands.maxSpeed ~/ 2,
                  ),
                  onReleased: () =>
                      roverService.sendCommand(RoverCommands.stop),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =================== CONTROL BUTTON WIDGET ===================

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onPressed;
  final VoidCallback? onReleased;
  final Color? backgroundColor;
  final Color? activeColor;
  final double elevation;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    this.onPressed,
    this.onReleased,
    this.backgroundColor,
    this.activeColor,
    this.elevation = 4,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBg = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final defaultActiveColor = theme.colorScheme.primary;

    final bgColor = widget.backgroundColor ?? defaultBg;
    final activeColor = widget.activeColor ?? defaultActiveColor;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onPressed?.call();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onReleased?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onReleased?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed ? activeColor : bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: widget.elevation,
                offset: Offset(0, widget.elevation / 2),
              ),
            BoxShadow(
              color: _isPressed
                  ? activeColor.withOpacity(0.5)
                  : Colors.black.withOpacity(0.1),
              spreadRadius: _isPressed ? widget.elevation / 2 : 0,
              blurRadius: _isPressed ? widget.elevation * 2 : widget.elevation,
            ),
          ],
          gradient: _isPressed
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bgColor, Color.lerp(bgColor, Colors.black, 0.1)!],
                ),
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: _isPressed
              ? Colors.white
              : theme.colorScheme.onSurface.withOpacity(0.9),
        ),
      ),
    );
  }
}
