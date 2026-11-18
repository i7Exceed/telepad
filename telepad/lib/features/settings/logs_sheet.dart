// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';

import '../../core/localization.dart';
import '../../core/theme.dart';

class LogsSheet extends StatelessWidget {
  final List<String> logs;
  final VoidCallback onClear;

  const LogsSheet({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sem = Theme.of(context).extension<TelePadSemanticColors>()!;

    return ValueListenableBuilder<Locale>(
      valueListenable: I18n.localeNotifier,
      builder: (context, _, __) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.terminal_rounded, color: cs.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          I18n.t('logs'),
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: logs.isEmpty ? null : onClear,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(88, 48),
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: logs.isEmpty
                              ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                              : sem.danger,
                        ),
                        label: Text(
                          I18n.t('clearLogs'),
                          style: TextStyle(
                            color: logs.isEmpty
                                ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                                : sem.danger,
                            fontSize: 13,
                          ),
                        ),
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
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sem.logSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: logs.isEmpty
                          ? Center(
                              child: Text(
                                I18n.t('noLogs'),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final entry = logs[logs.length - 1 - index];
                                final isError = entry.startsWith('[ERR]');
                                final isOk = entry.startsWith('[OK]');

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        isError
                                            ? Icons.error_outline_rounded
                                            : isOk
                                                ? Icons.check_circle_outline_rounded
                                                : Icons.chevron_right_rounded,
                                        size: 15,
                                        color: isError
                                            ? sem.danger
                                            : isOk
                                                ? sem.success
                                                : cs.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          entry,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: isError
                                                ? sem.danger
                                                : isOk
                                                    ? sem.success
                                                    : cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
