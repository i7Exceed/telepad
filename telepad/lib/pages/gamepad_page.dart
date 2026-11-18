// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/localization.dart';
import '../core/theme.dart';
import '../features/discovery/server_discovery_sheet.dart';
import '../features/relay/controller_telemetry.dart';
import '../features/relay/physical_relay_view.dart';
import '../features/settings/help_sheet.dart';
import '../features/settings/logs_sheet.dart';
import '../features/settings/settings_sheet.dart';
import '../features/touchpad/virtual_touchpad_view.dart';
import '../features/virtual_pad/virtual_gamepad_view.dart';
import '../services/settings_service.dart';
import '../services/udp_service.dart';

class GamepadPage extends StatefulWidget {
  final UdpTransport? transport;
  final SettingsService? settingsService;
  final bool enableHardwarePlugins;
  final Duration handshakeTimeout;

  const GamepadPage({
    super.key,
    this.transport,
    this.settingsService,
    this.enableHardwarePlugins = true,
    this.handshakeTimeout = const Duration(seconds: 3),
  });

  @override
  State<GamepadPage> createState() => _GamepadPageState();
}

class _GamepadPageState extends State<GamepadPage> {
  late final UdpTransport _udp;
  late final SettingsService _settings;
  final ControllerTelemetry _telemetry = ControllerTelemetry();

  String _targetIp = '';
  int _targetPort = 8888;
  String _targetPin = '';
  String _targetName = '';

  final _focusNode = FocusNode();

  int _controlMode = 0; // 0 = Physical, 1 = Virtual, 2 = Touchpad
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  bool _isPinError = false;
  int? _latencyMs;

  final List<String> _logs = [];
  DateTime _lastAnalogLog = DateTime(2000);

  StreamSubscription<GamepadEvent>? _gamepadSubscription;
  String? _detectedControllerName;
  double _lsX = 0, _lsY = 0;
  double _rsX = 0, _rsY = 0;
  DateTime _lastAnalogEvent = DateTime(2000);

  StreamSubscription<String>? _udpMessageSub;
  Timer? _handshakeTimer;
  Timer? _pingTimer;
  Timer? _vibrationTimer;
  Timer? _amoledHintTimer;
  DateTime? _lastPongAt;

  bool _isVibrating = false;
  bool _amoledSaver = false;
  bool _showAmoledHint = false;
  int _currentVibLarge = 0;
  int _currentVibSmall = 0;
  bool _hasAmplitudeControl = false;

  static const int _maxLogs = 80;

  @override
  void initState() {
    super.initState();
    _udp = widget.transport ?? UdpService();
    _settings = widget.settingsService ?? SettingsService();
    _udpMessageSub = _udp.messages.listen(_onServerMessage);
    _initAsync();
  }

  Future<void> _initAsync() async {
    await _settings.load();
    if (!mounted) return;

    setState(() {
      _controlMode = _settings.lastControlMode;
      if (_settings.lastIp.isNotEmpty) {
        _targetIp = _settings.lastIp;
        _targetPort = _settings.lastPort;
      }
    });

    if (widget.enableHardwarePlugins) {
      _initGamepad();
      _initVibrationSupport();
      try {
        await WakelockPlus.enable();
      } catch (_) {}
    }

    _log('TelePad initialized (${I18n.currentLocale.languageCode.toUpperCase()}).');
  }

  Future<void> _initVibrationSupport() async {
    try {
      _hasAmplitudeControl = await Vibration.hasAmplitudeControl();
    } catch (_) {
      _hasAmplitudeControl = false;
    }
  }

  Future<void> _initGamepad() async {
    try {
      final pads = await Gamepads.list();
      if (pads.isNotEmpty && mounted) {
        setState(() => _detectedControllerName = pads.first.name);
        _log('[OK] Hardware gamepad: ${pads.first.name}');
      }
      _gamepadSubscription = Gamepads.events.listen(_onGamepadEvent);
    } catch (e) {
      _log('[ERR] Gamepad plugin error: $e');
    }
  }

  @override
  void dispose() {
    _handshakeTimer?.cancel();
    _pingTimer?.cancel();
    _vibrationTimer?.cancel();
    _amoledHintTimer?.cancel();
    _gamepadSubscription?.cancel();
    _udpMessageSub?.cancel();
    if (widget.enableHardwarePlugins) {
      try {
        WakelockPlus.disable();
      } catch (_) {}
    }
    _telemetry.dispose();
    _udp.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _log(String msg) {
    _logs.add(msg);
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }
  }

  // ── Connection Handshake & Heartbeat ──────────────────────────────────

  Future<void> _connectTo({
    required String name,
    required String ip,
    required int port,
    required String pin,
  }) async {
    _handshakeTimer?.cancel();
    _stopPingTimer();

    setState(() {
      _targetName = name;
      _targetIp = ip;
      _targetPort = port;
      _targetPin = pin;
      _status = ConnectionStatus.connecting;
      _errorMessage = null;
      _isPinError = false;
      _latencyMs = null;
    });

    final socketErr = await _udp.openSocket(ip, port);
    if (!mounted) return;

    if (socketErr != null) {
      final msg = I18n.tf('socketError', {'error': socketErr});
      _log('[ERR] $msg');
      setState(() {
        _status = ConnectionStatus.error;
        _errorMessage = msg;
      });
      return;
    }

    _log('Authenticating with $ip:$port...');
    _udp.send('AUTH|$pin');

    _handshakeTimer = Timer(widget.handshakeTimeout, () {
      if (!mounted) return;
      if (_status == ConnectionStatus.connecting) {
        _udp.closeSocket();
        final timeoutMsg = I18n.tf('timeoutError', {'ip': ip, 'port': port});
        _log('[ERR] Handshake timeout ($ip:$port).');
        setState(() {
          _status = ConnectionStatus.error;
          _errorMessage = timeoutMsg;
        });
      }
    });
  }

  void _disconnect({bool isError = false, String? errorMsg, bool pinErr = false}) {
    _handshakeTimer?.cancel();
    _stopPingTimer();
    _udp.closeSocket();
    _stopVibration();

    setState(() {
      _status = isError ? ConnectionStatus.error : ConnectionStatus.disconnected;
      _errorMessage = errorMsg;
      _isPinError = pinErr;
      _latencyMs = null;
    });
  }

  void _onServerMessage(String message) {
    if (!mounted) return;

    if (message == 'AUTH_OK') {
      _handshakeTimer?.cancel();
      _lastPongAt = DateTime.now();
      final msg = I18n.tf('authSuccess', {'ip': _targetIp, 'port': _targetPort});
      _log('[OK] $msg');
      setState(() {
        _status = ConnectionStatus.connected;
        _errorMessage = null;
        _isPinError = false;
      });
      _settings.recordServer(
        name: _targetName.isNotEmpty ? _targetName : 'PC-$_targetIp',
        ip: _targetIp,
        port: _targetPort,
      );
      _startPingTimer();
      _showInfoSnackBar(msg);
    } else if (message == 'AUTH_FAIL') {
      final msg = I18n.t('authFailed');
      _log('[ERR] $msg');
      _disconnect(isError: true, errorMsg: msg, pinErr: true);
    } else if (message.startsWith('PONG|')) {
      final parts = message.split('|');
      if (parts.length >= 2) {
        final sent = int.tryParse(parts[1]);
        if (sent != null) {
          final rtt =
              (DateTime.now().millisecondsSinceEpoch - sent).clamp(0, 9999);
          _lastPongAt = DateTime.now();
          setState(() => _latencyMs = rtt);
        }
      }
    } else if (message.startsWith('VIB|')) {
      final parts = message.split('|');
      if (parts.length >= 3) {
        final large = int.tryParse(parts[1]) ?? 0;
        final small = int.tryParse(parts[2]) ?? 0;
        _handleVibration(large, small);
      }
    }
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != ConnectionStatus.connected) {
        _stopPingTimer();
        return;
      }

      if (_lastPongAt != null &&
          DateTime.now().difference(_lastPongAt!).inSeconds >= 5) {
        final msg = I18n.t('heartbeatLost');
        _log('[ERR] $msg');
        _disconnect(isError: true, errorMsg: msg);
        return;
      }

      final ts = DateTime.now().millisecondsSinceEpoch;
      _udp.send('PING|$ts');
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _showInfoSnackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  // ── Vibration Engine ──────────────────────────────────────────────────

  void _handleVibration(int large, int small) {
    _currentVibLarge = large;
    _currentVibSmall = small;

    if (large > 0 || small > 0) {
      if (!_isVibrating) {
        setState(() => _isVibrating = true);
        _triggerContinuousVibration();
      }
    } else {
      _stopVibration();
    }
  }

  void _stopVibration() {
    if (_isVibrating && mounted) {
      setState(() => _isVibrating = false);
    } else {
      _isVibrating = false;
    }
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    if (widget.enableHardwarePlugins) {
      try {
        Vibration.cancel();
      } catch (_) {}
    }
  }

  void _triggerContinuousVibration() {
    if (!_isVibrating || !widget.enableHardwarePlugins) return;

    try {
      if (_hasAmplitudeControl) {
        if (_currentVibSmall > 50 && _currentVibLarge < 50) {
          final int amp = _currentVibSmall.clamp(1, 255);
          Vibration.vibrate(
            pattern: [0, 30, 20, 30],
            intensities: [0, amp, 0, (amp * 0.8).toInt()],
          );
          _vibrationTimer?.cancel();
          _vibrationTimer = Timer(
            const Duration(milliseconds: 80),
            _triggerContinuousVibration,
          );
        } else {
          final rawAmp = _currentVibLarge > _currentVibSmall
              ? _currentVibLarge
              : _currentVibSmall;
          final int amp = rawAmp.clamp(1, 255);
          Vibration.vibrate(duration: 150, amplitude: amp);
          _vibrationTimer?.cancel();
          _vibrationTimer = Timer(
            const Duration(milliseconds: 150),
            _triggerContinuousVibration,
          );
        }
      } else {
        Vibration.vibrate(duration: 200);
        _vibrationTimer?.cancel();
        _vibrationTimer = Timer(
          const Duration(milliseconds: 150),
          _triggerContinuousVibration,
        );
      }
    } catch (_) {}
  }

  // ── Input Handlers (Physical & Virtual — zero page rebuilds) ──────────

  void _onGamepadEvent(GamepadEvent event) {
    if (_detectedControllerName == null && event.gamepadId.isNotEmpty) {
      Gamepads.list().then((pads) {
        if (!mounted) return;
        setState(() {
          _detectedControllerName =
              pads.isNotEmpty ? pads.first.name : event.gamepadId;
        });
      }).catchError((_) {});
    }

    if (_controlMode != 0) return;

    if (event.type == KeyType.analog) {
      bool lsChanged = false;
      bool rsChanged = false;

      if (event.key == '0' || event.key == 'AXIS_X') {
        _lsX = event.value;
        lsChanged = true;
      } else if (event.key == '1' || event.key == 'AXIS_Y') {
        _lsY = event.value;
        lsChanged = true;
      } else if (event.key == '2' || event.key == 'AXIS_Z') {
        _rsX = event.value;
        rsChanged = true;
      } else if (event.key == '3' || event.key == 'AXIS_RZ') {
        _rsY = event.value;
        rsChanged = true;
      }

      if (lsChanged || rsChanged) {
        _lastAnalogEvent = DateTime.now();
        final dz = C.deadzone.value;
        double deadLsX = _lsX.abs() < dz ? 0.0 : _lsX;
        double deadLsY = _lsY.abs() < dz ? 0.0 : _lsY;
        double deadRsX = _rsX.abs() < dz ? 0.0 : _rsX;
        double deadRsY = _rsY.abs() < dz ? 0.0 : _rsY;

        if (lsChanged) _sendAnalog('LS', deadLsX, deadLsY);
        if (rsChanged) _sendAnalog('RS', deadRsX, deadRsY);

        _telemetry.setAnalog(
          lsX: deadLsX,
          lsY: deadLsY,
          rsX: deadRsX,
          rsY: deadRsY,
        );
      }
    }
  }

  void _sendButton(String key, bool pressed) {
    final payload = 'B|$key|${pressed ? 1 : 0}';
    _udp.send(payload);
    _log(payload);
    _telemetry.setButton(key, pressed);
  }

  void _sendAnalog(String axis, double x, double y) {
    final payload = 'A|$axis|${x.toStringAsFixed(3)}|${y.toStringAsFixed(3)}';
    _udp.send(payload);

    final now = DateTime.now();
    if (now.difference(_lastAnalogLog).inMilliseconds > 120) {
      _log(payload);
      _lastAnalogLog = now;
    }
  }

  static final _keyMap = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.gameButtonA: 'A',
    LogicalKeyboardKey.gameButtonB: 'B',
    LogicalKeyboardKey.gameButtonX: 'X',
    LogicalKeyboardKey.gameButtonY: 'Y',
    LogicalKeyboardKey.arrowUp: 'DPAD_UP',
    LogicalKeyboardKey.arrowDown: 'DPAD_DOWN',
    LogicalKeyboardKey.arrowLeft: 'DPAD_LEFT',
    LogicalKeyboardKey.arrowRight: 'DPAD_RIGHT',
    LogicalKeyboardKey.gameButtonLeft1: 'LB',
    LogicalKeyboardKey.gameButtonRight1: 'RB',
    LogicalKeyboardKey.gameButtonLeft2: 'LT',
    LogicalKeyboardKey.gameButtonRight2: 'RT',
    LogicalKeyboardKey.gameButtonStart: 'START',
    LogicalKeyboardKey.gameButtonSelect: 'SELECT',
    LogicalKeyboardKey.gameButtonThumbLeft: 'LS_CLICK',
    LogicalKeyboardKey.gameButtonThumbRight: 'RS_CLICK',
    LogicalKeyboardKey.gameButtonMode: 'HOME',
  };

  KeyEventResult _onHardwareKey(FocusNode _, KeyEvent ev) {
    if (_controlMode != 0) return KeyEventResult.ignored;

    final btn = _keyMap[ev.logicalKey];
    if (btn == null) return KeyEventResult.ignored;

    if (btn.startsWith('DPAD_')) {
      if (DateTime.now().difference(_lastAnalogEvent).inMilliseconds < 150) {
        return KeyEventResult.handled;
      }
    }

    if (ev is KeyDownEvent && !_telemetry.activeButtons.contains(btn)) {
      _sendButton(btn, true);
    } else if (ev is KeyUpEvent) {
      _sendButton(btn, false);
    }
    return KeyEventResult.handled;
  }

  // ── Mode & AMOLED Controls ────────────────────────────────────────────

  void _setMode(int mode) {
    setState(() => _controlMode = mode);
    _settings.saveControlMode(mode);
    if (mode == 0) {
      _focusNode.requestFocus();
    }
  }

  void _enableAmoledSaver() {
    setState(() {
      _amoledSaver = true;
      _showAmoledHint = true;
    });
    _amoledHintTimer?.cancel();
    _amoledHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showAmoledHint = false);
    });
  }

  void _disableAmoledSaver() {
    _amoledHintTimer?.cancel();
    setState(() {
      _amoledSaver = false;
      _showAmoledHint = false;
    });
    _focusNode.requestFocus();
  }

  // ── Sheets ────────────────────────────────────────────────────────────

  void _showDiscoverySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ServerDiscoverySheet(
        udpService: _udp,
        initialIp: _targetIp,
        initialPort: _targetPort,
        initialPin: _targetPin,
        recentServers: _settings.recentServers,
        onOpenHelp: _showHelpSheet,
        onSelect: (name, ip, port, pin) {
          Navigator.pop(ctx);
          _connectTo(name: name, ip: ip, port: port, pin: pin);
        },
      ),
    ).then((_) => _focusNode.requestFocus());
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SettingsSheet(settingsService: _settings),
    ).then((_) => _focusNode.requestFocus());
  }

  void _showLogsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => LogsSheet(
        logs: _logs,
        onClear: () {
          setState(() => _logs.clear());
          Navigator.pop(ctx);
          _showInfoSnackBar(I18n.t('logsCleared'));
        },
      ),
    ).then((_) => _focusNode.requestFocus());
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const HelpSheet(),
    ).then((_) => _focusNode.requestFocus());
  }

  // ── Build UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 600;
    final useRail = size.width >= 600 && size.height >= 500;
    final useTopSegmented = size.width >= 600 && size.height < 500;

    return ValueListenableBuilder<Locale>(
      valueListenable: I18n.localeNotifier,
      builder: (context, _, __) {
        return ValueListenableBuilder<int>(
          valueListenable: C.activeThemeIndex,
          builder: (context, _, __) {
            return ValueListenableBuilder<double>(
              valueListenable: C.deadzone,
              builder: (context, deadzone, _) {
                final bodyContent = _controlMode == 1
                    ? VirtualGamepadView(
                        deadzone: deadzone,
                        isConnected: _status == ConnectionStatus.connected,
                        onButton: _sendButton,
                        onAnalog: _sendAnalog,
                        onOpenDiscovery: _showDiscoverySheet,
                      )
                    : _controlMode == 2
                        ? VirtualTouchpadView(
                            onSend: _udp.send,
                            onLog: _log,
                          )
                        : PhysicalRelayView(
                            status: _status,
                            latencyMs: _latencyMs,
                            isRumbling: _isVibrating,
                            controllerName: _detectedControllerName,
                            telemetry: _telemetry,
                            lastServerLabel: _targetIp.isNotEmpty
                                ? '$_targetIp:$_targetPort'
                                : null,
                            onEnableAmoledSaver: _enableAmoledSaver,
                            onOpenDiscovery: _showDiscoverySheet,
                            onQuickReconnect: _targetIp.isNotEmpty
                                ? () => _connectTo(
                                      name: _targetName,
                                      ip: _targetIp,
                                      port: _targetPort,
                                      pin: _targetPin,
                                    )
                                : null,
                          );

                return PopScope(
                  canPop: !_amoledSaver,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && _amoledSaver) {
                      _disableAmoledSaver();
                    }
                  },
                  child: Focus(
                    focusNode: _focusNode,
                    autofocus: true,
                    descendantsAreFocusable: false,
                    descendantsAreTraversable: false,
                    onKeyEvent: _onHardwareKey,
                    child: Scaffold(
                      backgroundColor: cs.surfaceContainerLow,
                      bottomNavigationBar:
                          isCompact ? _buildBottomNavBar() : null,
                      body: Stack(
                        children: [
                          SafeArea(
                            child: Column(
                              children: [
                                _buildTopBar(useTopSegmented),
                                if (_status == ConnectionStatus.error &&
                                    _errorMessage != null)
                                  _buildErrorBanner(_errorMessage!),
                                Expanded(
                                  child: useRail
                                      ? Row(
                                          children: [
                                            _buildNavigationRail(),
                                            VerticalDivider(
                                              width: 1,
                                              color: cs.outlineVariant,
                                            ),
                                            Expanded(child: bodyContent),
                                          ],
                                        )
                                      : bodyContent,
                                ),
                              ],
                            ),
                          ),
                          if (_amoledSaver) _buildAmoledSaverOverlay(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(bool showTopSegmented) {
    final cs = Theme.of(context).colorScheme;
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_esports_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            I18n.t('appTitle'),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 10),

          if (showTopSegmented) ...[
            Flexible(child: _buildConnectionPill()),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildLandscapeModeSelector(),
                ),
              ),
            ),
          ] else
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildConnectionPill(),
              ),
            ),

          if (_status == ConnectionStatus.connected && showTopSegmented) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _disconnect(),
              tooltip: I18n.t('disconnect'),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: Icon(Icons.power_settings_new_rounded, color: sem.danger),
            ),
          ],

          SizedBox(
            width: 48,
            height: 48,
            child: PopupMenuButton<String>(
              tooltip: I18n.t('moreOptions'),
              icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
              padding: EdgeInsets.zero,
              color: cs.surface,
              onSelected: (val) {
                switch (val) {
                  case 'disconnect':
                    _disconnect();
                  case 'amoled':
                    _enableAmoledSaver();
                  case 'settings':
                    _showSettingsSheet();
                  case 'logs':
                    _showLogsSheet();
                  case 'help':
                    _showHelpSheet();
                }
              },
              itemBuilder: (_) => [
                if (_status == ConnectionStatus.connected)
                  PopupMenuItem(
                    value: 'disconnect',
                    child: Row(
                      children: [
                        Icon(Icons.power_settings_new_rounded,
                            size: 20, color: sem.danger),
                        const SizedBox(width: 10),
                        Text(I18n.t('disconnect'),
                            style: TextStyle(color: sem.danger)),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'amoled',
                  child: Row(
                    children: [
                      Icon(Icons.battery_saver_rounded,
                          size: 20, color: sem.success),
                      const SizedBox(width: 10),
                      Text(I18n.t('amoledSaver'),
                          style: TextStyle(color: cs.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: 10),
                      Text(I18n.t('settings'),
                          style: TextStyle(color: cs.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logs',
                  child: Row(
                    children: [
                      Icon(Icons.terminal_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(I18n.t('logs'),
                          style: TextStyle(color: cs.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(I18n.t('helpGuide'),
                          style: TextStyle(color: cs.onSurface)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPill() {
    final cs = Theme.of(context).colorScheme;
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;

    Color bg;
    Color border;
    Color fg;
    IconData icon;
    String label;

    switch (_status) {
      case ConnectionStatus.connecting:
        bg = sem.warningBg;
        border = sem.warning.withValues(alpha: 0.5);
        fg = sem.warning;
        icon = Icons.sync_rounded;
        label = I18n.t('connecting');
      case ConnectionStatus.connected:
        bg = sem.successBg;
        border = sem.success.withValues(alpha: 0.55);
        fg = sem.success;
        icon = Icons.wifi_tethering_rounded;
        final ping = _latencyMs != null
            ? ' • ${I18n.tf('pingValue', {'ms': _latencyMs!})}'
            : '';
        label = '$_targetIp$ping';
      case ConnectionStatus.error:
        bg = sem.dangerBg;
        border = sem.danger.withValues(alpha: 0.55);
        fg = sem.danger;
        icon = Icons.error_outline_rounded;
        label = I18n.t('connectionError');
      case ConnectionStatus.disconnected:
        bg = cs.surfaceContainerHigh;
        border = cs.primary.withValues(alpha: 0.45);
        fg = cs.primary;
        icon = Icons.search_rounded;
        label = I18n.t('scanServer');
    }

    return Semantics(
      button: true,
      liveRegion: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap:
            _status == ConnectionStatus.connecting ? null : _showDiscoverySheet,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_status == ConnectionStatus.connecting)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else
                    Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildLandscapeModeSelector() {
    final cs = Theme.of(context).colorScheme;

    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(48, 48)),
        visualDensity: VisualDensity.standard,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primaryContainer;
          return cs.surfaceContainerHigh;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurfaceVariant;
        }),
        side: WidgetStateProperty.all(BorderSide(color: cs.outlineVariant)),
      ),
      segments: [
        ButtonSegment(
          value: 0,
          icon: const Icon(Icons.sports_esports_rounded, size: 18),
          label: Text(I18n.t('modePhysical')),
        ),
        ButtonSegment(
          value: 1,
          icon: const Icon(Icons.gamepad_rounded, size: 18),
          label: Text(I18n.t('modeVirtual')),
        ),
        ButtonSegment(
          value: 2,
          icon: const Icon(Icons.touch_app_rounded, size: 18),
          label: Text(I18n.t('modeTouchpad')),
        ),
      ],
      selected: {_controlMode},
      onSelectionChanged: (set) => _setMode(set.first),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _controlMode,
      onDestinationSelected: _setMode,
      labelType: NavigationRailLabelType.all,
      minWidth: 76,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.sports_esports_outlined),
          selectedIcon: const Icon(Icons.sports_esports_rounded),
          label: Text(I18n.t('modePhysical')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.gamepad_outlined),
          selectedIcon: const Icon(Icons.gamepad_rounded),
          label: Text(I18n.t('modeVirtual')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.touch_app_outlined),
          selectedIcon: const Icon(Icons.touch_app_rounded),
          label: Text(I18n.t('modeTouchpad')),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return NavigationBar(
      selectedIndex: _controlMode,
      onDestinationSelected: _setMode,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.sports_esports_outlined),
          selectedIcon: const Icon(Icons.sports_esports_rounded),
          label: I18n.t('modePhysical'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.gamepad_outlined),
          selectedIcon: const Icon(Icons.gamepad_rounded),
          label: I18n.t('modeVirtual'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.touch_app_outlined),
          selectedIcon: const Icon(Icons.touch_app_rounded),
          label: I18n.t('modeTouchpad'),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    final cs = Theme.of(context).colorScheme;
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: sem.dangerBg,
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: sem.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: cs.onSurface, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: _isPinError
                  ? _showDiscoverySheet
                  : () {
                      if (_targetIp.isNotEmpty) {
                        _connectTo(
                          name: _targetName,
                          ip: _targetIp,
                          port: _targetPort,
                          pin: _targetPin,
                        );
                      } else {
                        _showDiscoverySheet();
                      }
                    },
              style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
              child: Text(_isPinError ? I18n.t('editPin') : I18n.t('retry')),
            ),
            if (!_isPinError)
              IconButton(
                onPressed: _showHelpSheet,
                tooltip: I18n.t('helpGuide'),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                icon: Icon(
                  Icons.help_outline_rounded,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
              ),
            IconButton(
              onPressed: () => setState(() => _errorMessage = null),
              tooltip: I18n.t('close'),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: Icon(Icons.close_rounded,
                  color: cs.onSurfaceVariant, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmoledSaverOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => _showAmoledHint = true);
          _amoledHintTimer?.cancel();
          _amoledHintTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showAmoledHint = false);
          });
        },
        onDoubleTap: _disableAmoledSaver,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: AnimatedOpacity(
              opacity: _showAmoledHint ? 1.0 : 0.18,
              duration: C.motionDuration(context, 250),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_saver_rounded,
                    color: _showAmoledHint
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFFCBD5E1),
                    size: 28,
                  ),
                  if (_showAmoledHint) ...[
                    const SizedBox(height: 12),
                    Text(
                      I18n.t('amoledActiveNotice'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _disableAmoledSaver,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF8FAFC),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        minimumSize: const Size(140, 48),
                      ),
                      child: Text(I18n.t('amoledWakeHint')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
