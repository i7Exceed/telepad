// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';

import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../services/udp_service.dart';
import 'controller_telemetry.dart';

class PhysicalRelayView extends StatelessWidget {
  final ConnectionStatus status;
  final int? latencyMs;
  final bool isRumbling;
  final String? controllerName;
  final ControllerTelemetry telemetry;
  final String? lastServerLabel;
  final VoidCallback onEnableAmoledSaver;
  final VoidCallback onOpenDiscovery;
  final VoidCallback? onQuickReconnect;

  const PhysicalRelayView({
    super.key,
    required this.status,
    required this.latencyMs,
    required this.isRumbling,
    required this.controllerName,
    required this.telemetry,
    this.lastServerLabel,
    required this.onEnableAmoledSaver,
    required this.onOpenDiscovery,
    this.onQuickReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;
    final isConnected = status == ConnectionStatus.connected;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Interactive Live Controller Telemetry Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isConnected
                        ? cs.primary.withValues(alpha: 0.45)
                        : cs.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports_esports_rounded,
                          size: 20,
                          color: isConnected ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            I18n.t('diagnosticsTitle'),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isRumbling || (isConnected && latencyMs != null)) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (isRumbling)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: sem.dangerBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: sem.danger.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.vibration_rounded,
                                        size: 14, color: sem.danger),
                                    const SizedBox(width: 4),
                                    Text(
                                      I18n.t('rumbleActive'),
                                      style: TextStyle(
                                        color: sem.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isConnected && latencyMs != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: sem.successBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  I18n.tf('pingValue', {'ms': latencyMs!}),
                                  style: TextStyle(
                                    color: sem.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Live Vector Gamepad Telemetry (repaints directly via ChangeNotifier)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 185),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ListenableBuilder(
                          listenable: telemetry,
                          builder: (context, child) {
                            return Semantics(
                              label: I18n.t('diagnosticsTitle'),
                              value: telemetry.semanticSummary(),
                              child: child,
                            );
                          },
                          child: CustomPaint(
                            painter: _LiveControllerPainter(
                              telemetry: telemetry,
                              accent: cs.primary,
                              onAccent: cs.onPrimary,
                              surface: cs.surfaceContainerHigh,
                              border: cs.outlineVariant,
                              textPrimary: cs.onSurface,
                              textSecondary: cs.onSurfaceVariant,
                              btnA: C.btnA,
                              btnB: C.btnB,
                              btnX: C.btnX,
                              btnY: C.btnY,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hardware Detection Status Line
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controllerName != null
                                ? Icons.usb_rounded
                                : Icons.info_outline_rounded,
                            size: 18,
                            color: controllerName != null
                                ? sem.success
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controllerName != null
                                  ? I18n.tf(
                                      'detectedController',
                                      {'name': controllerName!},
                                    )
                                  : I18n.t('waitingController'),
                              style: TextStyle(
                                color: controllerName != null
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Guidance Copy
              Text(
                I18n.t('relayInfo'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Primary Action Row (>= 48dp touch targets)
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (!isConnected &&
                      lastServerLabel != null &&
                      onQuickReconnect != null)
                    FilledButton.icon(
                      onPressed: status == ConnectionStatus.connecting
                          ? null
                          : onQuickReconnect,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        minimumSize: const Size(150, 48),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      label: Text(
                        '${I18n.t('reconnect')} ($lastServerLabel)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (!isConnected)
                    FilledButton.tonalIcon(
                      onPressed: onOpenDiscovery,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            lastServerLabel != null ? cs.surface : cs.primary,
                        foregroundColor: lastServerLabel != null
                            ? cs.onSurface
                            : cs.onPrimary,
                        side: lastServerLabel != null
                            ? BorderSide(
                                color: cs.primary.withValues(alpha: 0.45),
                              )
                            : null,
                        minimumSize: const Size(140, 48),
                      ),
                      icon: const Icon(Icons.wifi_find_rounded, size: 20),
                      label: Text(
                        I18n.t('scanServer'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: onEnableAmoledSaver,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outline),
                      minimumSize: const Size(160, 48),
                    ),
                    icon: const Icon(Icons.battery_saver_rounded, size: 20),
                    label: Text(
                      I18n.t('amoledSaver'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveControllerPainter extends CustomPainter {
  final ControllerTelemetry telemetry;
  final Color accent;
  final Color onAccent;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color btnA;
  final Color btnB;
  final Color btnX;
  final Color btnY;

  _LiveControllerPainter({
    required this.telemetry,
    required this.accent,
    required this.onAccent,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.btnA,
    required this.btnB,
    required this.btnX,
    required this.btnY,
  }) : super(repaint: telemetry);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final activeButtons = telemetry.activeButtons;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, w - 8, h - 8),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, Paint()..color = surface);
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _drawTopBarButton(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.07, w * 0.22, h * 0.08),
      'LT',
      activeButtons.contains('LT'),
    );
    _drawTopBarButton(
      canvas,
      Rect.fromLTWH(w * 0.70, h * 0.07, w * 0.22, h * 0.08),
      'RT',
      activeButtons.contains('RT'),
    );
    _drawTopBarButton(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.17, w * 0.22, h * 0.08),
      'LB',
      activeButtons.contains('LB'),
    );
    _drawTopBarButton(
      canvas,
      Rect.fromLTWH(w * 0.70, h * 0.17, w * 0.22, h * 0.08),
      'RB',
      activeButtons.contains('RB'),
    );

    _drawStick(
      canvas,
      Offset(w * 0.20, h * 0.48),
      h * 0.16,
      telemetry.lsX,
      telemetry.lsY,
      activeButtons.contains('LS_CLICK'),
    );

    _drawDPad(
      canvas,
      Offset(w * 0.34, h * 0.74),
      h * 0.085,
      activeButtons,
    );

    _drawSystemPill(
      canvas,
      Offset(w * 0.43, h * 0.45),
      activeButtons.contains('SELECT'),
    );
    _drawCircleBtn(
      canvas,
      Offset(w * 0.50, h * 0.45),
      h * 0.065,
      activeButtons.contains('HOME'),
      accent,
      'H',
    );
    _drawSystemPill(
      canvas,
      Offset(w * 0.57, h * 0.45),
      activeButtons.contains('START'),
    );

    _drawStick(
      canvas,
      Offset(w * 0.66, h * 0.74),
      h * 0.15,
      telemetry.rsX,
      telemetry.rsY,
      activeButtons.contains('RS_CLICK'),
    );

    final faceCenter = Offset(w * 0.80, h * 0.48);
    final offset = h * 0.13;
    final r = h * 0.065;
    _drawCircleBtn(canvas, faceCenter + Offset(0, -offset), r,
        activeButtons.contains('Y'), btnY, 'Y');
    _drawCircleBtn(canvas, faceCenter + Offset(0, offset), r,
        activeButtons.contains('A'), btnA, 'A');
    _drawCircleBtn(canvas, faceCenter + Offset(-offset, 0), r,
        activeButtons.contains('X'), btnX, 'X');
    _drawCircleBtn(canvas, faceCenter + Offset(offset, 0), r,
        activeButtons.contains('B'), btnB, 'B');
  }

  void _drawTopBarButton(Canvas canvas, Rect rect, String label, bool pressed) {
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = pressed
            ? accent.withValues(alpha: 0.28)
            : border.withValues(alpha: 0.25),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = pressed ? accent : border
        ..style = PaintingStyle.stroke
        ..strokeWidth = pressed ? 1.8 : 1.0,
    );
    _paintLabel(
      canvas,
      label,
      rect.center,
      pressed ? accent : textSecondary,
      10,
    );
  }

  void _drawStick(
    Canvas canvas,
    Offset center,
    double radius,
    double sx,
    double sy,
    bool clicked,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = clicked ? accent : border
        ..style = PaintingStyle.stroke
        ..strokeWidth = clicked ? 2.0 : 1.2,
    );
    final dotOffset = Offset(
      center.dx + (sx.clamp(-1.0, 1.0) * (radius * 0.65)),
      center.dy - (sy.clamp(-1.0, 1.0) * (radius * 0.65)),
    );
    final active = sx.abs() > 0.01 || sy.abs() > 0.01 || clicked;
    canvas.drawCircle(
      dotOffset,
      radius * 0.36,
      Paint()..color = active ? accent : textSecondary.withValues(alpha: 0.45),
    );
  }

  void _drawDPad(
    Canvas canvas,
    Offset center,
    double unit,
    Set<String> activeButtons,
  ) {
    _drawDPadCell(
      canvas,
      Rect.fromCenter(
          center: center + Offset(0, -unit), width: unit, height: unit),
      activeButtons.contains('DPAD_UP'),
    );
    _drawDPadCell(
      canvas,
      Rect.fromCenter(
          center: center + Offset(0, unit), width: unit, height: unit),
      activeButtons.contains('DPAD_DOWN'),
    );
    _drawDPadCell(
      canvas,
      Rect.fromCenter(
          center: center + Offset(-unit, 0), width: unit, height: unit),
      activeButtons.contains('DPAD_LEFT'),
    );
    _drawDPadCell(
      canvas,
      Rect.fromCenter(
          center: center + Offset(unit, 0), width: unit, height: unit),
      activeButtons.contains('DPAD_RIGHT'),
    );
  }

  void _drawDPadCell(Canvas canvas, Rect rect, bool pressed) {
    canvas.drawRect(
      rect,
      Paint()..color = pressed ? accent : border.withValues(alpha: 0.35),
    );
  }

  void _drawSystemPill(Canvas canvas, Offset center, bool pressed) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 16, height: 9),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = pressed ? accent : textSecondary.withValues(alpha: 0.4),
    );
  }

  void _drawCircleBtn(
    Canvas canvas,
    Offset center,
    double radius,
    bool pressed,
    Color color,
    String label,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = pressed ? color : color.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = pressed ? color : color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = pressed ? 2.0 : 1.2,
    );
    _paintLabel(
      canvas,
      label,
      center,
      pressed ? onAccent : textPrimary,
      10,
    );
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double fontSize,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _LiveControllerPainter old) {
    return old.telemetry != telemetry ||
        old.accent != accent ||
        old.onAccent != onAccent ||
        old.surface != surface ||
        old.border != border ||
        old.textPrimary != textPrimary ||
        old.textSecondary != textSecondary ||
        old.btnA != btnA ||
        old.btnB != btnB ||
        old.btnX != btnX ||
        old.btnY != btnY;
  }
}
