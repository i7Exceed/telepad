// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization.dart';
import 'core/theme.dart';
import 'pages/gamepad_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent unintended keyboard/gamepad focus highlight borders
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const TelePadApp());
}

class TelePadApp extends StatelessWidget {
  const TelePadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: I18n.localeNotifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<int>(
          valueListenable: C.activeThemeIndex,
          builder: (context, _, __) {
            return MaterialApp(
              title: 'TelePad',
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('id'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
              theme: C.toMaterialTheme(),
              home: const GamepadPage(),
            );
          },
        );
      },
    );
  }
}
