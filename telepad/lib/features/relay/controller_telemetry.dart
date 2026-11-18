// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Isolated high-frequency telemetry model so hardware button/stick events
/// repaint the controller visualizer directly without rebuilding the page tree.
class ControllerTelemetry extends ChangeNotifier {
  final Set<String> _activeButtons = {};
  double _lsX = 0;
  double _lsY = 0;
  double _rsX = 0;
  double _rsY = 0;

  UnmodifiableSetView<String> get activeButtons =>
      UnmodifiableSetView(_activeButtons);
  double get lsX => _lsX;
  double get lsY => _lsY;
  double get rsX => _rsX;
  double get rsY => _rsY;

  void setButton(String key, bool pressed) {
    final changed =
        pressed ? _activeButtons.add(key) : _activeButtons.remove(key);
    if (changed) {
      notifyListeners();
    }
  }

  void setAnalog({
    double? lsX,
    double? lsY,
    double? rsX,
    double? rsY,
  }) {
    final nextLsX = lsX ?? _lsX;
    final nextLsY = lsY ?? _lsY;
    final nextRsX = rsX ?? _rsX;
    final nextRsY = rsY ?? _rsY;

    if (nextLsX == _lsX &&
        nextLsY == _lsY &&
        nextRsX == _rsX &&
        nextRsY == _rsY) {
      return;
    }

    _lsX = nextLsX;
    _lsY = nextLsY;
    _rsX = nextRsX;
    _rsY = nextRsY;
    notifyListeners();
  }

  String semanticSummary() {
    if (_activeButtons.isEmpty &&
        _lsX.abs() < 0.05 &&
        _lsY.abs() < 0.05 &&
        _rsX.abs() < 0.05 &&
        _rsY.abs() < 0.05) {
      return 'Idle';
    }
    final parts = <String>[];
    if (_activeButtons.isNotEmpty) {
      parts.add(_activeButtons.join(', '));
    }
    if (_lsX.abs() >= 0.05 || _lsY.abs() >= 0.05) {
      parts.add('LS');
    }
    if (_rsX.abs() >= 0.05 || _rsY.abs() >= 0.05) {
      parts.add('RS');
    }
    return parts.join(' • ');
  }
}
