// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import '../core/theme.dart';

class DPadWidget extends StatelessWidget {
  final void Function(String key, bool pressed) onButton;
  const DPadWidget({super.key, required this.onButton});

  @override
  Widget build(BuildContext context) {
    const double size = 156;
    const double arm = size / 3; // 52dp >= 48dp touch target minimum

    return ValueListenableBuilder<int>(
      valueListenable: C.activeThemeIndex,
      builder: (context, _, __) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(size, size),
                painter: _DPadPainter(
                  bgColor: C.bgCard,
                  dpadColor: C.dpad,
                  borderColor: C.glassBorder,
                  accentColor: C.cyan,
                ),
              ),
              Positioned(
                top: 0,
                left: arm,
                width: arm,
                height: arm,
                child: _DPadButton(
                  keyName: 'DPAD_UP',
                  semanticLabel: 'D-Pad Up',
                  icon: Icons.keyboard_arrow_up_rounded,
                  onButton: onButton,
                ),
              ),
              Positioned(
                bottom: 0,
                left: arm,
                width: arm,
                height: arm,
                child: _DPadButton(
                  keyName: 'DPAD_DOWN',
                  semanticLabel: 'D-Pad Down',
                  icon: Icons.keyboard_arrow_down_rounded,
                  onButton: onButton,
                ),
              ),
              Positioned(
                top: arm,
                left: 0,
                width: arm,
                height: arm,
                child: _DPadButton(
                  keyName: 'DPAD_LEFT',
                  semanticLabel: 'D-Pad Left',
                  icon: Icons.keyboard_arrow_left_rounded,
                  onButton: onButton,
                ),
              ),
              Positioned(
                top: arm,
                right: 0,
                width: arm,
                height: arm,
                child: _DPadButton(
                  keyName: 'DPAD_RIGHT',
                  semanticLabel: 'D-Pad Right',
                  icon: Icons.keyboard_arrow_right_rounded,
                  onButton: onButton,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DPadButton extends StatefulWidget {
  final String keyName;
  final String semanticLabel;
  final IconData icon;
  final void Function(String, bool) onButton;

  const _DPadButton({
    required this.keyName,
    required this.semanticLabel,
    required this.icon,
    required this.onButton,
  });

  @override
  State<_DPadButton> createState() => _DPadButtonState();
}

class _DPadButtonState extends State<_DPadButton> {
  bool _pressed = false;

  void _down() {
    if (_pressed) return;
    C.triggerHaptic('light');
    setState(() => _pressed = true);
    widget.onButton(widget.keyName, true);
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onButton(widget.keyName, false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeAccent = cs.primary;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: AnimatedContainer(
          duration: C.motionDuration(context, 60),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _pressed ? activeAccent.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: _pressed
                ? Border.all(color: activeAccent.withValues(alpha: 0.6), width: 1.5)
                : null,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: _pressed ? activeAccent : cs.onSurfaceVariant,
              size: _pressed ? 30 : 26,
            ),
          ),
        ),
      ),
    );
  }
}

class _DPadPainter extends CustomPainter {
  final Color bgColor;
  final Color dpadColor;
  final Color borderColor;
  final Color accentColor;

  _DPadPainter({
    required this.bgColor,
    required this.dpadColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = w / 3;
    const radius = Radius.circular(12);

    final crossPath = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, t, w, t), radius))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t, 0, t, h), radius));

    final basePaint = Paint()
      ..color = dpadColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(crossPath, basePaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(crossPath, borderPaint);

    final center = Offset(w / 2, h / 2);
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = accentColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DPadPainter oldDelegate) {
    return oldDelegate.bgColor != bgColor ||
        oldDelegate.dpadColor != dpadColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.accentColor != accentColor;
  }
}
