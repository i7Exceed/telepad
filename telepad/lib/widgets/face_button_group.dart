// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import '../core/theme.dart';

class FaceButtonGroup extends StatelessWidget {
  final void Function(String key, bool pressed) onButton;
  const FaceButtonGroup({super.key, required this.onButton});

  @override
  Widget build(BuildContext context) {
    const double area = 160;
    const double btn = 52;
    const double off = (area - btn) / 2;

    return ValueListenableBuilder<int>(
      valueListenable: C.activeThemeIndex,
      builder: (context, _, __) {
        return SizedBox(
          width: area,
          height: area,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Y (top)
              Positioned(
                top: 0,
                left: off,
                child: _FaceBtn(
                  keyName: 'Y',
                  label: 'Y',
                  color: C.btnY,
                  onButton: onButton,
                ),
              ),
              // A (bottom)
              Positioned(
                bottom: 0,
                left: off,
                child: _FaceBtn(
                  keyName: 'A',
                  label: 'A',
                  color: C.btnA,
                  onButton: onButton,
                ),
              ),
              // X (left)
              Positioned(
                top: off,
                left: 0,
                child: _FaceBtn(
                  keyName: 'X',
                  label: 'X',
                  color: C.btnX,
                  onButton: onButton,
                ),
              ),
              // B (right)
              Positioned(
                top: off,
                right: 0,
                child: _FaceBtn(
                  keyName: 'B',
                  label: 'B',
                  color: C.btnB,
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

class _FaceBtn extends StatefulWidget {
  final String keyName;
  final String label;
  final Color color;
  final void Function(String key, bool pressed) onButton;

  const _FaceBtn({
    required this.keyName,
    required this.label,
    required this.color,
    required this.onButton,
  });

  @override
  State<_FaceBtn> createState() => _FaceBtnState();
}

class _FaceBtnState extends State<_FaceBtn> {
  bool _pressed = false;

  void _down() {
    if (_pressed) return;
    C.triggerHaptic('selection');
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
    const double size = 50;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: AnimatedContainer(
          duration: C.motionDuration(context, 60),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed ? widget.color.withValues(alpha: 0.28) : C.dpad,
            border: Border.all(
              color: _pressed ? widget.color : widget.color.withValues(alpha: 0.55),
              width: _pressed ? 2.4 : 1.4,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: _pressed ? widget.color : cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
