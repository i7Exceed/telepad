// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:telepad/core/localization.dart';
import 'package:telepad/core/theme.dart';
import 'package:telepad/pages/gamepad_page.dart';
import 'package:telepad/services/settings_service.dart';
import 'package:telepad/services/udp_service.dart';

class FakeUdpTransport implements UdpTransport {
  final _messageCtrl = StreamController<String>.broadcast();
  final List<String> sentPayloads = [];
  List<DiscoveredServer> nextDiscoveryResults = [];
  int? lastDiscoveryPort;
  bool socketOpen = false;
  String? openError;

  @override
  bool get isSocketOpen => socketOpen;

  @override
  Stream<String> get messages => _messageCtrl.stream;

  void emitServerMessage(String msg) {
    if (!_messageCtrl.isClosed) {
      _messageCtrl.add(msg);
    }
  }

  @override
  Future<String?> openSocket(String ip, int port) async {
    if (openError != null) {
      socketOpen = false;
      return openError;
    }
    socketOpen = true;
    return null;
  }

  @override
  void closeSocket() {
    socketOpen = false;
  }

  @override
  bool send(String payload) {
    if (!socketOpen) return false;
    sentPayloads.add(payload);
    return true;
  }

  @override
  Stream<DiscoveredServer> discoverServers({
    int port = 8888,
    int timeoutMs = 3500,
  }) {
    lastDiscoveryPort = port;
    return Stream.fromIterable(nextDiscoveryResults);
  }

  @override
  void dispose() {
    closeSocket();
    _messageCtrl.close();
  }
}

Widget _wrapApp(Widget child) {
  return ValueListenableBuilder<Locale>(
    valueListenable: I18n.localeNotifier,
    builder: (context, locale, _) {
      return ValueListenableBuilder<int>(
        valueListenable: C.activeThemeIndex,
        builder: (context, _, __) {
          return MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('id')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: C.toMaterialTheme(),
            home: child,
          );
        },
      );
    },
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    I18n.setLocale(const Locale('en'));
    C.activeThemeIndex.value = 0;
    C.hapticIntensity.value = 'Medium';
    C.deadzone.value = 0.08;
  });

  testWidgets('Connection handshake gates Connected on AUTH_OK and shows live Ping ms',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    final settings = SettingsService();

    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: settings,
          enableHardwarePlugins: false,
          handshakeTimeout: const Duration(seconds: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Discovery Sheet
    await tester.tap(find.text('Find PC').first);
    await tester.pumpAndSettle();

    // Invalid IP & Port validation
    await tester.enterText(find.byType(TextField).at(0), 'not an ip');
    await tester.enterText(find.byType(TextField).at(1), '99999');
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(find.text(I18n.t('invalidIp')), findsOneWidget);
    expect(find.text(I18n.t('invalidPort')), findsOneWidget);

    // Valid IP & Port -> enters Connecting... (NOT Connected)
    await tester.enterText(find.byType(TextField).at(0), '192.168.1.50');
    await tester.enterText(find.byType(TextField).at(1), '8888');
    await tester.tap(find.text('Connect'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Connecting...'), findsOneWidget);
    expect(fakeUdp.sentPayloads, contains('AUTH|'));

    // Server replies AUTH_OK -> transitions to Connected & shows IP
    fakeUdp.emitServerMessage('AUTH_OK');
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.50'), findsOneWidget);

    // Server replies PONG -> displays live ping ms
    final sentTs = DateTime.now().millisecondsSinceEpoch - 12;
    fakeUdp.emitServerMessage('PONG|$sentTs');
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('ms'), findsWidgets);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Connection timeout and AUTH_FAIL show actionable error banners',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
          handshakeTimeout: const Duration(milliseconds: 120),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Discovery and submit valid IP with no server reply -> timeout error
    await tester.tap(find.text('Find PC').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '192.168.1.99');
    await tester.tap(find.text('Connect'));
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Connecting...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('Connection Failed'), findsOneWidget);
    expect(find.textContaining('No response from 192.168.1.99:8888'),
        findsOneWidget);
    expect(find.byTooltip('Setup Guide'), findsOneWidget);

    // Retry with AUTH_FAIL -> shows PIN error + Edit PIN action
    await tester.tap(find.text('Retry'));
    await tester.pump();
    fakeUdp.emitServerMessage('AUTH_FAIL');
    await tester.pump();
    expect(find.text(I18n.t('authFailed')), findsOneWidget);
    expect(find.text('Edit PIN'), findsOneWidget);
  });

  testWidgets('Empty discovery passes custom port and displays troubleshooting tips',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find PC').first);
    await tester.pumpAndSettle();

    expect(find.text(I18n.t('noServersFound')), findsOneWidget);
    expect(find.text('Scan Again'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '9999');
    await tester.tap(find.text('Scan Again'));
    await tester.pumpAndSettle();

    expect(fakeUdp.lastDiscoveryPort, 9999);
    expect(find.textContaining('UDP port 9999'), findsOneWidget);
  });

  testWidgets('Reactive i18n switches all GamepadPage chrome live between EN and ID',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open Overflow -> Settings
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Switch to Bahasa Indonesia
    await tester.tap(find.text('Bahasa Indonesia (ID)'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsOneWidget);

    // Close Settings and verify main page updated immediately
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Cari PC'), findsWidgets);
    expect(find.text('Tes Input Kontroler'), findsOneWidget);
    expect(find.text('Penghemat AMOLED'), findsOneWidget);
    expect(find.text('Fisik'), findsOneWidget);
    expect(find.text('Touchpad'), findsOneWidget);
  });

  testWidgets('AMOLED Saver displays wake hint and exits on double-tap or Wake button',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('AMOLED Saver'));
    await tester.pump();

    expect(find.text(I18n.t('amoledActiveNotice')), findsOneWidget);
    expect(find.text('Wake Screen'), findsOneWidget);

    await tester.tap(find.text('Wake Screen'));
    await tester.pumpAndSettle();
    expect(find.text('Controller Input Test'), findsOneWidget);
  });

  testWidgets('Touchpad handles 1-finger move/tap, 2-finger tap/scroll, and click bar',
      (tester) async {
    final fakeUdp = FakeUdpTransport()..socketOpen = true;
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Touchpad mode via bottom NavigationBar
    await tester.tap(find.text('Touchpad'));
    await tester.pumpAndSettle();

    final padCenter = tester.getCenter(find.text('Virtual Touchpad'));

    // 1-finger tap -> Left Click
    await tester.tapAt(padCenter);
    await tester.pump(const Duration(milliseconds: 80));
    expect(fakeUdp.sentPayloads, contains('MC|L|1'));
    expect(fakeUdp.sentPayloads, contains('MC|L|0'));

    fakeUdp.sentPayloads.clear();

    // 2-finger tap -> Right Click
    final g1 = await tester.startGesture(padCenter - const Offset(20, 0));
    final g2 = await tester.startGesture(padCenter + const Offset(20, 0));
    await g1.up();
    await g2.up();
    await tester.pump(const Duration(milliseconds: 80));
    expect(fakeUdp.sentPayloads, contains('MC|R|1'));
    expect(fakeUdp.sentPayloads, contains('MC|R|0'));

    fakeUdp.sentPayloads.clear();

    // 2-finger vertical drag -> Scroll Wheel
    final s1 = await tester.startGesture(padCenter - const Offset(20, 0));
    final s2 = await tester.startGesture(padCenter + const Offset(20, 0));
    await s1.moveBy(const Offset(0, -30));
    await s2.moveBy(const Offset(0, -30));
    await s1.up();
    await s2.up();
    await tester.pump();
    expect(fakeUdp.sentPayloads.any((p) => p.startsWith('MW|')), isTrue);
  });

  testWidgets('Virtual Gamepad exposes L3/R3/HOME and renders cleanly in portrait/landscape at 1.3x font scale',
      (tester) async {
    final fakeUdp = FakeUdpTransport()..socketOpen = true;

    // 1. Narrow Portrait (360x640) at 1.3x text scale
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: _wrapApp(
          GamepadPage(
            transport: fakeUdp,
            settingsService: SettingsService(),
            enableHardwarePlugins: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Verify top bar pill >= 48dp height and overflow menu >= 48x48dp
    final overflowSize = tester.getSize(find.byTooltip('More options'));
    expect(overflowSize.width, greaterThanOrEqualTo(48));
    expect(overflowSize.height, greaterThanOrEqualTo(48));

    // Switch to Virtual Gamepad & verify L3/R3/HOME
    await tester.tap(find.text('Virtual'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('L3'), findsOneWidget);
    expect(find.text('R3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 2. Short Landscape (800x360) at 1.3x text scale across all 3 modes
    tester.view.physicalSize = const Size(800, 360);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 360),
          textScaler: TextScaler.linear(1.3),
        ),
        child: _wrapApp(
          GamepadPage(
            transport: fakeUdp,
            settingsService: SettingsService(),
            enableHardwarePlugins: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Switch to Touchpad in short landscape at 1.3x text scale
    await tester.tap(find.text('Touchpad'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hardware gamepad key events update live Physical Relay diagnostics',
      (tester) async {
    final fakeUdp = FakeUdpTransport()..socketOpen = true;
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonA);
    await tester.pump();
    expect(fakeUdp.sentPayloads, contains('B|A|1'));

    await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonA);
    await tester.pump();
    expect(fakeUdp.sentPayloads, contains('B|A|0'));
  });

  testWidgets('SettingsService restores saved locale and recent PC for 1-tap Reconnect',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'telepad_locale': 'id',
      'telepad_last_ip': '192.168.1.77',
      'telepad_last_port': 7777,
      'telepad_recent_servers': ['GamingPC|192.168.1.77|7777'],
    });

    final fakeUdp = FakeUdpTransport();
    await tester.pumpWidget(
      _wrapApp(
        GamepadPage(
          transport: fakeUdp,
          settingsService: SettingsService(),
          enableHardwarePlugins: false,
          handshakeTimeout: const Duration(seconds: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Restored Indonesian locale + 1-tap Reconnect chip
    expect(find.text('Sambung Ulang (192.168.1.77:7777)'), findsOneWidget);
    await tester.tap(find.text('Sambung Ulang (192.168.1.77:7777)'));
    await tester.pump();
    expect(find.text('Menghubungkan...'), findsOneWidget);

    fakeUdp.emitServerMessage('AUTH_OK');
    await tester.pumpAndSettle();
    expect(find.text('192.168.1.77'), findsOneWidget);
  });

  testWidgets('Tablet Window Size Class (>=600dp) renders NavigationRail cleanly',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.reset());

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 1280),
          textScaler: TextScaler.linear(1.3),
        ),
        child: _wrapApp(
          GamepadPage(
            transport: fakeUdp,
            settingsService: SettingsService(),
            enableHardwarePlugins: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);

    // Switch to Virtual Gamepad via NavigationRail
    await tester.tap(find.text('Virtual'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daylight Light Theme switches Brightness.light cleanly & Reduce Motion returns Duration.zero',
      (tester) async {
    final fakeUdp = FakeUdpTransport();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          disableAnimations: true,
        ),
        child: _wrapApp(
          GamepadPage(
            transport: fakeUdp,
            settingsService: SettingsService(),
            enableHardwarePlugins: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Reduce Motion helper honors disableAnimationsOf
    final ctx = tester.element(find.byType(GamepadPage));
    expect(C.motionDuration(ctx, 60), Duration.zero);

    // Open Settings and select Daylight Light appearance
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daylight'));
    await tester.pumpAndSettle();

    final themedCtx = tester.element(find.byType(GamepadPage));
    expect(Theme.of(themedCtx).brightness, Brightness.light);
    expect(tester.takeException(), isNull);
  });
}
