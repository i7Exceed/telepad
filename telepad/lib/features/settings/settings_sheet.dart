// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';

import '../../core/localization.dart';
import '../../core/theme.dart';
import '../../services/settings_service.dart';

class SettingsSheet extends StatelessWidget {
  final SettingsService settingsService;

  const SettingsSheet({
    super.key,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: I18n.localeNotifier,
      builder: (context, currentLocale, _) {
        return ValueListenableBuilder<int>(
          valueListenable: C.activeThemeIndex,
          builder: (context, activeTheme, _) {
            final cs = Theme.of(context).colorScheme;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, color: cs.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            I18n.t('settings'),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text(
                      I18n.t('language'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _OptionButton(
                            label: 'English (EN)',
                            selected: currentLocale.languageCode == 'en',
                            onTap: () {
                              I18n.setLocale(const Locale('en'));
                              settingsService.saveLocale('en');
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _OptionButton(
                            label: 'Bahasa Indonesia (ID)',
                            selected: currentLocale.languageCode == 'id',
                            onTap: () {
                              I18n.setLocale(const Locale('id'));
                              settingsService.saveLocale('id');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Text(
                      I18n.t('theme'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final chipW = (constraints.maxWidth - 8) / 2;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int i = 0; i < C.themes.length; i++)
                              SizedBox(
                                width: chipW,
                                child: _OptionButton(
                                  label: C.themes[i].name,
                                  selected: activeTheme == i,
                                  onTap: () {
                                    C.activeThemeIndex.value = i;
                                    settingsService.saveThemeIndex(i);
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    Text(
                      I18n.t('hapticIntensity'),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: C.hapticIntensity,
                      builder: (context, intensity, _) {
                        final levels = const [
                          ('Off', 'hapticOff'),
                          ('Light', 'hapticLight'),
                          ('Medium', 'hapticMedium'),
                          ('Heavy', 'hapticHeavy'),
                        ];
                        return Row(
                          children: [
                            for (int i = 0; i < levels.length; i++) ...[
                              Expanded(
                                child: _OptionButton(
                                  label: I18n.t(levels[i].$2),
                                  selected: intensity == levels[i].$1,
                                  onTap: () {
                                    C.hapticIntensity.value = levels[i].$1;
                                    settingsService.saveHaptic(levels[i].$1);
                                    C.triggerHaptic('medium');
                                  },
                                ),
                              ),
                              if (i < levels.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    ValueListenableBuilder<double>(
                      valueListenable: C.deadzone,
                      builder: (context, dz, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  I18n.t('deadzone'),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${(dz * 100).round()}%',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Semantics(
                              label: I18n.t('deadzone'),
                              value: '${(dz * 100).round()}%',
                              child: Slider(
                                value: dz,
                                min: 0.02,
                                max: 0.25,
                                divisions: 23,
                                activeColor: cs.primary,
                                onChanged: (val) {
                                  C.deadzone.value = val;
                                },
                                onChangeEnd: (val) {
                                  settingsService.saveDeadzone(val);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    Column(
                      children: [
                        Text(
                          I18n.t('aboutTitle'),
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          I18n.t('aboutAuthor'),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          I18n.t('aboutCredits'),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: C.motionDuration(context, 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 1.6 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
