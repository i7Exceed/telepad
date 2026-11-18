// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import '../core/theme.dart';

class PillButton extends StatefulWidget {
  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final IconData? icon;

  const PillButton({
    super.key,
    required this.label,
    required this.onDown,
    required this.onUp,
    this.icon,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  void _down() {
    if (_pressed) return;
    C.triggerHaptic('selection');
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
    return ValueListenableBuilder<int>(
      valueListenable: C.activeThemeIndex,
      builder: (context, _, __) {
        final cs = Theme.of(context).colorScheme;
        final Color activeColor = cs.primary;

        return Semantics(
          button: true,
          label: widget.label,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => _down(),
            onPointerUp: (_) => _up(),
            onPointerCancel: (_) => _up(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
              child: Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: AnimatedContainer(
                  duration: C.motionDuration(context, 60),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _pressed ? activeColor.withValues(alpha: 0.24) : C.dpad,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _pressed ? activeColor : cs.outlineVariant,
                      width: _pressed ? 1.8 : 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 16,
                          color: _pressed ? activeColor : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: _pressed ? activeColor : cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
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
