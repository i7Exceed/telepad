// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import '../core/theme.dart';

class VirtualJoystick extends StatefulWidget {
  final double size;
  final void Function(double x, double y) onMove;
  final double deadzone;
  final String semanticLabel;

  const VirtualJoystick({
    super.key,
    required this.size,
    required this.onMove,
    this.deadzone = 0.08,
    this.semanticLabel = 'Analog Stick',
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knob = Offset.zero;
  bool _active = false;

  double get _maxR => widget.size / 2 - 22;

  void _update(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    var delta = local - center;
    final dist = delta.distance;

    if (dist > _maxR) {
      delta = delta / dist * _maxR;
    }

    setState(() {
      _knob = delta;
      _active = true;
    });

    double nx = delta.dx / _maxR;
    double ny = -delta.dy / _maxR;

    if (nx.abs() < widget.deadzone) nx = 0;
    if (ny.abs() < widget.deadzone) ny = 0;

    widget.onMove(nx, ny);
  }

  void _release() {
    setState(() {
      _knob = Offset.zero;
      _active = false;
    });
    widget.onMove(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: C.activeThemeIndex,
      builder: (context, _, __) {
        return Semantics(
          label: widget.semanticLabel,
          child: GestureDetector(
            onPanStart: (d) => _update(d.localPosition),
            onPanUpdate: (d) => _update(d.localPosition),
            onPanEnd: (_) => _release(),
            onPanCancel: _release,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _JoystickPainter(
                  knobOffset: _knob,
                  active: _active,
                  maxRadius: _maxR,
                  deadzone: widget.deadzone,
                  accentColor: C.cyan,
                  joyBaseColor: C.joyBase,
                  joyKnobColor: C.joyKnob,
                  glassBorderColor: C.glassBorder,
                  textColor: C.t3Super,
                  textMicroColor: C.t3Micro,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset knobOffset;
  final bool active;
  final double maxRadius;
  final double deadzone;
  final Color accentColor;
  final Color joyBaseColor;
  final Color joyKnobColor;
  final Color glassBorderColor;
  final Color textColor;
  final Color textMicroColor;

  _JoystickPainter({
    required this.knobOffset,
    required this.active,
    required this.maxRadius,
    required this.deadzone,
    required this.accentColor,
    required this.joyBaseColor,
    required this.joyKnobColor,
    required this.glassBorderColor,
    required this.textColor,
    required this.textMicroColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseR = size.width / 2 - 4;

    canvas.drawCircle(
      center,
      baseR,
      Paint()
        ..color = joyBaseColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      baseR,
      Paint()
        ..color = active ? accentColor.withValues(alpha: 0.65) : glassBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final guide = Paint()
      ..color = textColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      guide,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      guide,
    );

    canvas.drawCircle(
      center,
      maxRadius * deadzone,
      Paint()
        ..color = accentColor.withValues(alpha: active ? 0.35 : 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawCircle(
      center,
      maxRadius,
      Paint()
        ..color = active ? accentColor.withValues(alpha: 0.35) : textMicroColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 1.8 : 1.0,
    );

    final knobC = center + knobOffset;
    const knobR = 22.0;

    if (active) {
      final shadowOffset = -knobOffset * 0.18;
      canvas.drawCircle(
        knobC + shadowOffset,
        knobR,
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );
    }

    final Color currentKnobColor = active ? accentColor : joyKnobColor;

    canvas.drawCircle(
      knobC,
      knobR,
      Paint()..color = currentKnobColor.withValues(alpha: 0.95),
    );

    canvas.drawCircle(
      knobC,
      knobR * 0.58,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(
      knobC + const Offset(-5, -5),
      knobR * 0.25,
      Paint()..color = Colors.white.withValues(alpha: active ? 0.4 : 0.14),
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.knobOffset != knobOffset ||
      old.active != active ||
      old.deadzone != deadzone ||
      old.accentColor != accentColor ||
      old.joyBaseColor != joyBaseColor ||
      old.joyKnobColor != joyKnobColor;
}
