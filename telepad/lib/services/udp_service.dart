// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'dart:async';
import 'dart:io';

/// Represents a discovered server on the local network.
class DiscoveredServer {
  final String ip;
  final String name;
  final int port;

  const DiscoveredServer(this.ip, this.name, {this.port = 8888});
}

/// Connection lifecycle states for honest status visibility.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Abstract UDP transport for testability and decoupling.
abstract class UdpTransport {
  bool get isSocketOpen;
  Stream<String> get messages;

  Future<String?> openSocket(String ip, int port);
  void closeSocket();
  bool send(String payload);
  Stream<DiscoveredServer> discoverServers({int port = 8888, int timeoutMs = 3500});
  void dispose();
}

/// Lightweight, zero-allocation-friendly UDP sender and listener.
class UdpService implements UdpTransport {
  RawDatagramSocket? _socket;
  InternetAddress? _target;
  int _port = 8888;
  bool _active = false;

  @override
  bool get isSocketOpen => _active;

  final _messageController = StreamController<String>.broadcast();

  @override
  Stream<String> get messages => _messageController.stream;

  /// Validates an IPv4 address or non-whitespace hostname.
  static bool isValidHost(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.contains(RegExp(r'\s'))) return false;
    final parsed = InternetAddress.tryParse(trimmed);
    if (parsed != null) return parsed.type == InternetAddressType.IPv4;
    // Allow simple LAN hostnames (e.g. "gaming-pc" or "desktop.local")
    return RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9\-\.]{0,252}$').hasMatch(trimmed);
  }

  static int? parseValidPort(String input) {
    final p = int.tryParse(input.trim());
    if (p == null || p < 1 || p > 65535) return null;
    return p;
  }

  /// Bind a local UDP socket and resolve the target address.
  @override
  Future<String?> openSocket(String ip, int port) async {
    try {
      closeSocket();
      final resolved = InternetAddress.tryParse(ip.trim()) ??
          (await InternetAddress.lookup(ip.trim())).firstWhere(
            (addr) => addr.type == InternetAddressType.IPv4,
          );
      _target = resolved;
      _port = port;
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _active = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data).trim();
            if (!_messageController.isClosed) {
              _messageController.add(message);
            }
          }
        }
      });

      return null;
    } catch (e) {
      _active = false;
      return e.toString();
    }
  }

  @override
  void closeSocket() {
    _socket?.close();
    _socket = null;
    _active = false;
  }

  /// Fire-and-forget UDP send. Returns false if socket is not open.
  @override
  bool send(String payload) {
    if (!_active || _socket == null || _target == null) return false;
    _socket!.send(payload.codeUnits, _target!, _port);
    return true;
  }

  /// Broadcasts a discovery packet on [port] and listens for responses.
  @override
  Stream<DiscoveredServer> discoverServers({
    int port = 8888,
    int timeoutMs = 3500,
  }) {
    final controller = StreamController<DiscoveredServer>();
    final List<RawDatagramSocket> activeSockets = [];
    final Set<String> seenIps = {};
    bool cancelled = false;

    controller.onCancel = () {
      cancelled = true;
      for (var socket in activeSockets) {
        socket.close();
      }
    };

    Future(() async {
      try {
        final interfaces =
            await NetworkInterface.list(type: InternetAddressType.IPv4);

        try {
          final anySocket =
              await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          anySocket.broadcastEnabled = true;
          activeSockets.add(anySocket);
        } catch (_) {}

        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (addr.isLoopback) continue;
            try {
              final socket = await RawDatagramSocket.bind(addr, 0);
              socket.broadcastEnabled = true;
              activeSockets.add(socket);
            } catch (_) {}
          }
        }

        if (cancelled) return;

        for (var socket in activeSockets) {
          socket.listen((RawSocketEvent event) {
            if (event == RawSocketEvent.read) {
              final datagram = socket.receive();
              if (datagram != null) {
                final ip = datagram.address.address;
                final message = String.fromCharCodes(datagram.data).trim();

                if (!seenIps.contains(ip)) {
                  seenIps.add(ip);
                  if (!controller.isClosed) {
                    controller.add(DiscoveredServer(
                      ip,
                      message.isNotEmpty ? message : 'PC-$ip',
                      port: port,
                    ));
                  }
                }
              }
            }
          });
        }

        final payloadTele = 'DISCOVER_TELEPAD'.codeUnits;
        final payloadSir = 'DISCOVER_SIRPAD'.codeUnits;

        for (var socket in activeSockets) {
          socket.send(payloadTele, InternetAddress('255.255.255.255'), port);
          socket.send(payloadSir, InternetAddress('255.255.255.255'), port);

          try {
            final address = socket.address.address;
            if (address != '0.0.0.0') {
              final parts = address.split('.');
              if (parts.length == 4) {
                parts[3] = '255';
                final subnetBroadcast = parts.join('.');
                socket.send(payloadTele, InternetAddress(subnetBroadcast), port);
                socket.send(payloadSir, InternetAddress(subnetBroadcast), port);
              }
            }
          } catch (_) {}
        }

        await Future.delayed(Duration(milliseconds: timeoutMs));
      } catch (_) {
        // Discovery errors are non-fatal
      } finally {
        for (var socket in activeSockets) {
          socket.close();
        }
        if (!controller.isClosed) {
          await controller.close();
        }
      }
    });

    return controller.stream;
  }

  @override
  void dispose() {
    closeSocket();
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
