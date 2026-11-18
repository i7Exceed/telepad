// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';

import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../widgets/bumper_button.dart';
import '../../widgets/dpad_widget.dart';
import '../../widgets/face_button_group.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/virtual_joystick.dart';

class VirtualGamepadView extends StatelessWidget {
  final double deadzone;
  final bool isConnected;
  final void Function(String key, bool pressed) onButton;
  final void Function(String axis, double x, double y) onAnalog;
  final VoidCallback onOpenDiscovery;

  const VirtualGamepadView({
    super.key,
    required this.deadzone,
    required this.isConnected,
    required this.onButton,
    required this.onAnalog,
    required this.onOpenDiscovery,
  });

  @override
  Widget build(BuildContext context) {
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return Column(
      children: [
        if (!isConnected)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onOpenDiscovery,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sem.warningBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sem.warning.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 16, color: sem.warning),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        I18n.t('offlineControlsHint'),
                        style: TextStyle(
                          color: sem.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880, maxHeight: 540),
              child: isLandscape ? _buildLandscape() : _buildPortrait(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscape() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bumperPair('LB', 'LT'),
                const SizedBox(height: 10),
                VirtualJoystick(
                  size: 112,
                  deadzone: deadzone,
                  semanticLabel: I18n.t('leftStick'),
                  onMove: (x, y) => onAnalog('LS', x, y),
                ),
                const SizedBox(height: 8),
                DPadWidget(onButton: onButton),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PillButton(
                      label: 'SELECT',
                      onDown: () => onButton('SELECT', true),
                      onUp: () => onButton('SELECT', false),
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      label: 'START',
                      onDown: () => onButton('START', true),
                      onUp: () => onButton('START', false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'HOME',
                  icon: Icons.home_rounded,
                  onDown: () => onButton('HOME', true),
                  onUp: () => onButton('HOME', false),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PillButton(
                      label: 'L3',
                      onDown: () => onButton('LS_CLICK', true),
                      onUp: () => onButton('LS_CLICK', false),
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      label: 'R3',
                      onDown: () => onButton('RS_CLICK', true),
                      onUp: () => onButton('RS_CLICK', false),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _bumperPair('RB', 'RT'),
                const SizedBox(height: 10),
                FaceButtonGroup(onButton: onButton),
                const SizedBox(height: 8),
                VirtualJoystick(
                  size: 112,
                  deadzone: deadzone,
                  semanticLabel: I18n.t('rightStick'),
                  onMove: (x, y) => onAnalog('RS', x, y),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 372,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      BumperButton(
                        label: 'LB',
                        onDown: () => onButton('LB', true),
                        onUp: () => onButton('LB', false),
                      ),
                      const SizedBox(height: 8),
                      BumperButton(
                        label: 'LT',
                        onDown: () => onButton('LT', true),
                        onUp: () => onButton('LT', false),
                      ),
                    ],
                  ),
                  PillButton(
                    label: 'HOME',
                    icon: Icons.home_rounded,
                    onDown: () => onButton('HOME', true),
                    onUp: () => onButton('HOME', false),
                  ),
                  Column(
                    children: [
                      BumperButton(
                        label: 'RB',
                        onDown: () => onButton('RB', true),
                        onUp: () => onButton('RB', false),
                      ),
                      const SizedBox(height: 8),
                      BumperButton(
                        label: 'RT',
                        onDown: () => onButton('RT', true),
                        onUp: () => onButton('RT', false),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      VirtualJoystick(
                        size: 116,
                        deadzone: deadzone,
                        semanticLabel: I18n.t('leftStick'),
                        onMove: (x, y) => onAnalog('LS', x, y),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        I18n.t('leftStick'),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PillButton(
                        label: 'L3',
                        onDown: () => onButton('LS_CLICK', true),
                        onUp: () => onButton('LS_CLICK', false),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      VirtualJoystick(
                        size: 116,
                        deadzone: deadzone,
                        semanticLabel: I18n.t('rightStick'),
                        onMove: (x, y) => onAnalog('RS', x, y),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        I18n.t('rightStick'),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      PillButton(
                        label: 'R3',
                        onDown: () => onButton('RS_CLICK', true),
                        onUp: () => onButton('RS_CLICK', false),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DPadWidget(onButton: onButton),
                  FaceButtonGroup(onButton: onButton),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PillButton(
                    label: 'SELECT',
                    onDown: () => onButton('SELECT', true),
                    onUp: () => onButton('SELECT', false),
                  ),
                  const SizedBox(width: 28),
                  PillButton(
                    label: 'START',
                    onDown: () => onButton('START', true),
                    onUp: () => onButton('START', false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bumperPair(String b1, String b2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BumperButton(
          label: b1,
          onDown: () => onButton(b1, true),
          onUp: () => onButton(b1, false),
        ),
        const SizedBox(width: 10),
        BumperButton(
          label: b2,
          onDown: () => onButton(b2, true),
          onUp: () => onButton(b2, false),
        ),
      ],
    );
  }
}
