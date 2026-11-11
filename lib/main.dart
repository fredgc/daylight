// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'clock.dart';
import 'l10n/l10n_extension.dart';
import 'web_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    unawaited(() async {
      try {
        final info = await PackageInfo.fromPlatform();
        final ver = info.buildNumber.isNotEmpty
            ? '${info.version}+${info.buildNumber}'
            : info.version;
        await checkServerVersionAndReload(ver);
      } catch (_) {}
    }());
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  await LocaleController.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          locale: locale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale.languageCode) {
                  return supported;
                }
              }
            }
            return const Locale('en');
          },
          onGenerateTitle: (context) => context.l10n.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const LocalClock(),
        );
      },
    );
  }
}
