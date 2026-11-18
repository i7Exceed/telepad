// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization.dart';

class VirtualTouchpadView extends StatefulWidget {
  final void Function(String payload) onSend;
  final void Function(String message)? onLog;

  const VirtualTouchpadView({
    super.key,
    required this.onSend,
    this.onLog,
  });

  @override
  State<VirtualTouchpadView> createState() => _VirtualTouchpadViewState();
}

class _VirtualTouchpadViewState extends State<VirtualTouchpadView> {
  final Map<int, Offset> _activePointers = {};
  final Map<int, Offset> _downPositions = {};
  DateTime? _downTime;
  DateTime? _lastTapTime;
  int _maxPointersInGesture = 0;
  bool _moved = false;
  bool _dragLocked = false;
  bool _leftBtnPressed = false;
  bool _rightBtnPressed = false;

  void _onPointerDown(PointerDownEvent e) {
    _activePointers[e.pointer] = e.localPosition;
    _downPositions[e.pointer] = e.localPosition;

    if (_activePointers.length == 1) {
      _moved = false;
      _maxPointersInGesture = 1;
      final now = DateTime.now();
      _downTime = now;

      if (_lastTapTime != null &&
          now.difference(_lastTapTime!).inMilliseconds < 280) {
        _dragLocked = true;
        widget.onSend('MC|L|1');
        HapticFeedback.selectionClick();
        widget.onLog?.call('MC|L|1 (Drag Lock)');
      }
    } else if (_activePointers.length == 2) {
      _maxPointersInGesture = 2;
      if (_dragLocked) {
        _dragLocked = false;
        widget.onSend('MC|L|0');
      }
    } else if (_activePointers.length > _maxPointersInGesture) {
      _maxPointersInGesture = _activePointers.length;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    final prev = _activePointers[e.pointer];
    if (prev == null) return;

    final delta = e.localPosition - prev;
    _activePointers[e.pointer] = e.localPosition;

    final start = _downPositions[e.pointer] ?? e.localPosition;
    if ((e.localPosition - start).distance > 8.0) {
      _moved = true;
    }

    if (_activePointers.length == 1) {
      if (delta.dx != 0 || delta.dy != 0) {
        widget.onSend(
          'M|${delta.dx.toStringAsFixed(2)}|${delta.dy.toStringAsFixed(2)}',
        );
      }
    } else if (_activePointers.length == 2) {
      if (delta.dy.abs() > 0.2) {
        final scroll = (-delta.dy / 10).toStringAsFixed(2);
        widget.onSend('MW|$scroll');
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _activePointers.remove(e.pointer);
    _downPositions.remove(e.pointer);

    if (_activePointers.isEmpty) {
      if (_dragLocked) {
        _dragLocked = false;
        widget.onSend('MC|L|0');
        widget.onLog?.call('MC|L|0 (Drag Release)');
      } else if (!_moved && _downTime != null) {
        final durationMs = DateTime.now().difference(_downTime!).inMilliseconds;
        if (durationMs < 280) {
          if (_maxPointersInGesture == 2) {
            widget.onSend('MC|R|1');
            Future.delayed(const Duration(milliseconds: 50), () {
              widget.onSend('MC|R|0');
            });
            HapticFeedback.mediumImpact();
            widget.onLog?.call('MC|R|1 (Two-finger Tap)');
          } else if (_maxPointersInGesture == 1) {
            _lastTapTime = DateTime.now();
            widget.onSend('MC|L|1');
            Future.delayed(const Duration(milliseconds: 50), () {
              widget.onSend('MC|L|0');
            });
            HapticFeedback.lightImpact();
            widget.onLog?.call('MC|L|1 (Tap)');
          }
        }
      }
      _maxPointersInGesture = 0;
      _moved = false;
      _downTime = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _activePointers.remove(e.pointer);
    _downPositions.remove(e.pointer);
    if (_activePointers.isEmpty) {
      if (_dragLocked) {
        _dragLocked = false;
        widget.onSend('MC|L|0');
      }
      _maxPointersInGesture = 0;
      _moved = false;
      _downTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: I18n.t('modeTouchpadFull'),
                            hint: I18n.t('touchpadInfo'),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: _onPointerDown,
                              onPointerMove: _onPointerMove,
                              onPointerUp: _onPointerUp,
                              onPointerCancel: _onPointerCancel,
                              child: Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        color: cs.primary.withValues(alpha: 0.75),
                                        size: 40,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        I18n.t('modeTouchpadFull'),
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        I18n.t('touchpadInfo'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          label: I18n.t('scrollRailLabel'),
                          child: SizedBox(
                            width: 56,
                            height: double.infinity,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragUpdate: (details) {
                                final dy =
                                    (-details.delta.dy / 10).toStringAsFixed(2);
                                widget.onSend('MW|$dy');
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  border: Border(
                                    left: BorderSide(color: cs.outlineVariant),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.unfold_more_rounded,
                                        color: cs.onSurfaceVariant, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      I18n.t('scrollRailLabel'),
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: cs.outlineVariant)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: I18n.t('leftClick'),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) {
                                setState(() => _leftBtnPressed = true);
                                widget.onSend('MC|L|1');
                                HapticFeedback.lightImpact();
                              },
                              onPointerUp: (_) {
                                setState(() => _leftBtnPressed = false);
                                widget.onSend('MC|L|0');
                              },
                              onPointerCancel: (_) {
                                setState(() => _leftBtnPressed = false);
                                widget.onSend('MC|L|0');
                              },
                              child: Container(
                                color: _leftBtnPressed
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHigh,
                                alignment: Alignment.center,
                                child: Text(
                                  I18n.t('leftClick'),
                                  style: TextStyle(
                                    color: _leftBtnPressed
                                        ? cs.primary
                                        : cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, color: cs.outlineVariant),
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: I18n.t('rightClick'),
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) {
                                setState(() => _rightBtnPressed = true);
                                widget.onSend('MC|R|1');
                                HapticFeedback.lightImpact();
                              },
                              onPointerUp: (_) {
                                setState(() => _rightBtnPressed = false);
                                widget.onSend('MC|R|0');
                              },
                              onPointerCancel: (_) {
                                setState(() => _rightBtnPressed = false);
                                widget.onSend('MC|R|0');
                              },
                              child: Container(
                                color: _rightBtnPressed
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHigh,
                                alignment: Alignment.center,
                                child: Text(
                                  I18n.t('rightClick'),
                                  style: TextStyle(
                                    color: _rightBtnPressed
                                        ? cs.primary
                                        : cs.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
