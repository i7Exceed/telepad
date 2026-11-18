// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import '../core/theme.dart';

class BumperButton extends StatefulWidget {
  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const BumperButton({
    super.key,
    required this.label,
    required this.onDown,
    required this.onUp,
  });

  @override
  State<BumperButton> createState() => _BumperButtonState();
}

class _BumperButtonState extends State<BumperButton> {
  bool _pressed = false;

  void _down() {
    if (_pressed) return;
    C.triggerHaptic('light');
    setState(() => _pressed = true);
    widget.onDown();
  }

  void _up() {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onUp();
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.label.startsWith('L');
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isLeft ? 18 : 8),
      bottomLeft: const Radius.circular(8),
      topRight: Radius.circular(isLeft ? 8 : 18),
      bottomRight: const Radius.circular(8),
    );

    return ValueListenableBuilder<int>(
      valueListenable: C.activeThemeIndex,
      builder: (context, _, __) {
        final cs = Theme.of(context).colorScheme;
        final Color activeAccent = cs.primary;

        return Semantics(
          button: true,
          label: widget.label,
          child: Listener(
            onPointerDown: (_) => _down(),
            onPointerUp: (_) => _up(),
            onPointerCancel: (_) => _up(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 68, minHeight: 48),
              child: AnimatedContainer(
                duration: C.motionDuration(context, 60),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _pressed ? activeAccent.withValues(alpha: 0.24) : C.bumper,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: _pressed ? activeAccent : cs.outlineVariant,
                    width: _pressed ? 2.0 : 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: _pressed ? activeAccent : cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
