// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization.dart';
import '../core/theme.dart';

class SavedServer {
  final String name;
  final String ip;
  final int port;

  const SavedServer({
    required this.name,
    required this.ip,
    required this.port,
  });

  String encode() => '$name|$ip|$port';

  static SavedServer? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    final port = int.tryParse(parts[2]);
    if (port == null || port < 1 || port > 65535) return null;
    final ip = parts[1].trim();
    if (ip.isEmpty) return null;
    return SavedServer(name: parts[0].trim(), ip: ip, port: port);
  }
}

class SettingsService {
  static const _kLocale = 'telepad_locale';
  static const _kThemeIndex = 'telepad_theme_index';
  static const _kHaptic = 'telepad_haptic';
  static const _kDeadzone = 'telepad_deadzone';
  static const _kControlMode = 'telepad_control_mode';
  static const _kLastIp = 'telepad_last_ip';
  static const _kLastPort = 'telepad_last_port';
  static const _kRecentServers = 'telepad_recent_servers';

  String lastIp = '';
  int lastPort = 8888;
  int lastControlMode = 0;
  List<SavedServer> recentServers = [];

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lang = prefs.getString(_kLocale);
      if (lang == 'id' || lang == 'en') {
        I18n.setLocale(Locale(lang!));
      }

      final themeIdx = prefs.getInt(_kThemeIndex);
      if (themeIdx != null && themeIdx >= 0 && themeIdx < C.themes.length) {
        C.activeThemeIndex.value = themeIdx;
      }

      final haptic = prefs.getString(_kHaptic);
      if (haptic != null &&
          const {'Off', 'Light', 'Medium', 'Heavy'}.contains(haptic)) {
        C.hapticIntensity.value = haptic;
      }

      final dz = prefs.getDouble(_kDeadzone);
      if (dz != null && dz >= 0.02 && dz <= 0.25) {
        C.deadzone.value = dz;
      }

      final mode = prefs.getInt(_kControlMode);
      if (mode != null && mode >= 0 && mode <= 2) {
        lastControlMode = mode;
      }

      lastIp = prefs.getString(_kLastIp) ?? '';
      final savedPort = prefs.getInt(_kLastPort);
      if (savedPort != null && savedPort >= 1 && savedPort <= 65535) {
        lastPort = savedPort;
      }

      final rawList = prefs.getStringList(_kRecentServers) ?? const [];
      recentServers = rawList
          .map(SavedServer.decode)
          .whereType<SavedServer>()
          .toList();
    } catch (_) {
      // Fallback safely to defaults if storage unavailable
    }
  }

  Future<void> saveLocale(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocale, code);
    } catch (_) {}
  }

  Future<void> saveThemeIndex(int idx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeIndex, idx);
    } catch (_) {}
  }

  Future<void> saveHaptic(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHaptic, value);
    } catch (_) {}
  }

  Future<void> saveDeadzone(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kDeadzone, value);
    } catch (_) {}
  }

  Future<void> saveControlMode(int mode) async {
    lastControlMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kControlMode, mode);
    } catch (_) {}
  }

  Future<void> recordServer({
    required String name,
    required String ip,
    required int port,
  }) async {
    lastIp = ip;
    lastPort = port;
    final cleanName = name.trim().isEmpty ? 'PC-$ip' : name.trim();
    recentServers.removeWhere((s) => s.ip == ip && s.port == port);
    recentServers.insert(0, SavedServer(name: cleanName, ip: ip, port: port));
    if (recentServers.length > 5) {
      recentServers = recentServers.sublist(0, 5);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastIp, ip);
      await prefs.setInt(_kLastPort, port);
      await prefs.setStringList(
        _kRecentServers,
        recentServers.map((s) => s.encode()).toList(),
      );
    } catch (_) {}
  }
}
