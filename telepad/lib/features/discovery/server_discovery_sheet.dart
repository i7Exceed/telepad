// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../services/settings_service.dart';
import '../../services/udp_service.dart';

class ServerDiscoverySheet extends StatefulWidget {
  final UdpTransport udpService;
  final String initialIp;
  final int initialPort;
  final String initialPin;
  final List<SavedServer> recentServers;
  final void Function(String name, String ip, int port, String pin) onSelect;
  final VoidCallback onOpenHelp;

  const ServerDiscoverySheet({
    super.key,
    required this.udpService,
    required this.initialIp,
    required this.initialPort,
    required this.initialPin,
    required this.recentServers,
    required this.onSelect,
    required this.onOpenHelp,
  });

  @override
  State<ServerDiscoverySheet> createState() => _ServerDiscoverySheetState();
}

class _ServerDiscoverySheetState extends State<ServerDiscoverySheet> {
  final List<DiscoveredServer> _servers = [];
  StreamSubscription<DiscoveredServer>? _scanSub;
  bool _searching = true;

  late final TextEditingController _ipCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _pinCtrl;

  String? _ipError;
  String? _portError;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(text: widget.initialIp);
    _portCtrl = TextEditingController(text: widget.initialPort.toString());
    _pinCtrl = TextEditingController(text: widget.initialPin);
    _startSearch();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _startSearch() {
    _scanSub?.cancel();
    final port = UdpService.parseValidPort(_portCtrl.text) ?? widget.initialPort;
    setState(() {
      _searching = true;
      _servers.clear();
    });

    _scanSub = widget.udpService
        .discoverServers(port: port, timeoutMs: 3500)
        .listen(
      (server) {
        if (!mounted) return;
        setState(() {
          if (!_servers.any((s) => s.ip == server.ip)) {
            _servers.add(server);
          }
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _searching = false);
        }
      },
    );
  }

  void _cancelSearch() {
    _scanSub?.cancel();
    _scanSub = null;
    if (mounted) {
      setState(() => _searching = false);
    }
  }

  void _submitManual() {
    final ip = _ipCtrl.text.trim();
    final portStr = _portCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    String? ipErr;
    String? portErr;

    if (!UdpService.isValidHost(ip)) {
      ipErr = I18n.t('invalidIp');
    }
    final port = UdpService.parseValidPort(portStr);
    if (port == null) {
      portErr = I18n.t('invalidPort');
    }

    if (ipErr != null || portErr != null) {
      setState(() {
        _ipError = ipErr;
        _portError = portErr;
      });
      return;
    }

    widget.onSelect('PC-$ip', ip, port!, pin);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;
    final portPreview =
        UdpService.parseValidPort(_portCtrl.text) ?? widget.initialPort;

    return ValueListenableBuilder<Locale>(
      valueListenable: I18n.localeNotifier,
      builder: (context, _, __) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.radar_rounded, color: cs.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          I18n.t('scanServer'),
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_searching)
                        TextButton(
                          onPressed: _cancelSearch,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 48),
                          ),
                          child: Text(I18n.t('cancel')),
                        )
                      else
                        IconButton(
                          onPressed: _startSearch,
                          tooltip: I18n.t('scanAgain'),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          icon: Icon(Icons.refresh_rounded, color: cs.primary),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: I18n.t('close'),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        icon: Icon(Icons.close_rounded,
                            color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (_searching) ...[
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          _searching
                              ? I18n.t('scanning')
                              : I18n.tf(
                                  'scanComplete',
                                  {'count': _servers.length},
                                ),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_servers.isNotEmpty) ...[
                    Text(
                      I18n.t('discoveredServers'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final s in _servers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          minTileHeight: 56,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: cs.primary.withValues(alpha: 0.45),
                            ),
                          ),
                          tileColor: cs.surfaceContainerHigh,
                          leading:
                              Icon(Icons.computer_rounded, color: sem.success),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${s.ip}:${s.port} • ${I18n.t('tapToConnect')}',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_rounded,
                            color: cs.primary,
                          ),
                          onTap: () => widget.onSelect(
                            s.name,
                            s.ip,
                            s.port,
                            _pinCtrl.text.trim(),
                          ),
                        ),
                      ),
                  ] else if (!_searching) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            I18n.t('noServersFound'),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            I18n.tf(
                              'emptyDiscoveryTips',
                              {'port': portPreview},
                            ),
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _startSearch,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(120, 48),
                                ),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(I18n.t('scanAgain')),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onOpenHelp();
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(120, 48),
                                ),
                                icon: const Icon(Icons.help_outline_rounded,
                                    size: 18),
                                label: Text(I18n.t('helpGuide')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (widget.recentServers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      I18n.t('recentServers'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in widget.recentServers)
                          ActionChip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.padded,
                            avatar: Icon(Icons.history_rounded,
                                size: 18, color: cs.primary),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('${r.name} (${r.ip}:${r.port})'),
                            ),
                            backgroundColor: cs.surfaceContainerHigh,
                            side: BorderSide(color: cs.outlineVariant),
                            labelStyle: TextStyle(
                              color: cs.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            onPressed: () => widget.onSelect(
                              r.name,
                              r.ip,
                              r.port,
                              _pinCtrl.text.trim(),
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  Text(
                    I18n.t('manualConnect'),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _ipCtrl,
                          keyboardType: TextInputType.url,
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                          onChanged: (_) {
                            if (_ipError != null) {
                              setState(() => _ipError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: I18n.t('manualIp'),
                            hintText: I18n.t('manualIpHint'),
                            errorText: _ipError,
                            errorMaxLines: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _portCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: cs.onSurface, fontSize: 14),
                          onChanged: (_) {
                            if (_portError != null) {
                              setState(() => _portError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: I18n.t('port'),
                            hintText: I18n.t('portHint'),
                            errorText: _portError,
                            errorMaxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: cs.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: I18n.t('pin'),
                      hintText: I18n.t('pinHint'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _submitManual,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.link_rounded, size: 20),
                    label: Text(
                      I18n.t('connect'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
