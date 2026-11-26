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

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:daylight/clock.dart';
import 'package:daylight/l10n/l10n_extension.dart';
import 'package:daylight/location.dart';
import 'package:daylight/main.dart';
import 'package:daylight/theme_controller.dart';
import 'package:daylight/time.dart';
import 'package:location/location.dart';

void main() {
  setUp(() {
    rootBundle.clear();
    LocaleController.currentLocale.value = null;
    ThemeController.currentThemeMode.value = ThemeMode.system;
  });

  testWidgets('LocalClock smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LocalClock), findsOneWidget);
  });

  testWidgets('MyApp supports system dark mode and themes analog clock',
      (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.darkTheme?.brightness, Brightness.dark);

    final clockContext = tester.element(find.byType(DaylightAnalogClock));
    final colorScheme = Theme.of(clockContext).colorScheme;
    expect(colorScheme.brightness, Brightness.dark);

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DaylightAnalogClock),
        matching: find.byType(CustomPaint),
      ),
    );
    final dialPainter = customPaint.painter! as ClockDialPainter;
    final handsPainter = customPaint.foregroundPainter! as ClockHandsPainter;

    expect(dialPainter.dialColor, colorScheme.surfaceContainer);
    expect(dialPainter.markingColor, colorScheme.onSurface);
    expect(dialPainter.hourNumberColor, colorScheme.onSurface);
    expect(handsPainter.handColor, colorScheme.onSurface);

    final readoutContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(DaylightAnalogClock),
        matching: find.byType(Container),
      ),
    );
    final decoration = readoutContainer.decoration! as BoxDecoration;
    expect(decoration.border?.top.color, colorScheme.outline);
  });

  testWidgets('Analog clock uses light theme colors in light mode',
      (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final clockContext = tester.element(find.byType(DaylightAnalogClock));
    final colorScheme = Theme.of(clockContext).colorScheme;
    expect(colorScheme.brightness, Brightness.light);

    final customPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(DaylightAnalogClock),
        matching: find.byType(CustomPaint),
      ),
    );
    final dialPainter = customPaint.painter! as ClockDialPainter;
    final handsPainter = customPaint.foregroundPainter! as ClockHandsPainter;

    expect(dialPainter.dialColor, colorScheme.surfaceContainerLowest);
    expect(dialPainter.markingColor, colorScheme.onSurface);
    expect(dialPainter.hourNumberColor, colorScheme.onSurface);
    expect(handsPainter.handColor, colorScheme.onSurface);
  });

  testWidgets('Theme menu switches between dark, light, and system modes',
      (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Dark'),
        matching: find.byType(CheckedPopupMenuItem<ThemeMode>),
      ),
    );
    await tester.pumpAndSettle();

    expect(ThemeController.currentThemeMode.value, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    final darkContext = tester.element(find.byType(DaylightAnalogClock));
    expect(Theme.of(darkContext).colorScheme.brightness, Brightness.dark);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Light'),
        matching: find.byType(CheckedPopupMenuItem<ThemeMode>),
      ),
    );
    await tester.pumpAndSettle();

    expect(ThemeController.currentThemeMode.value, ThemeMode.light);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    final lightContext = tester.element(find.byType(DaylightAnalogClock));
    expect(Theme.of(lightContext).colorScheme.brightness, Brightness.light);
  });

  testWidgets('Renders in English', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LocalClock(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daylight Local Time'), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
  });

  testWidgets('Renders in Spanish', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LocalClock(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daylight - Hora solar local'), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
  });

  testWidgets(
      'Clock uses 12-hour format in US English and 24-hour format in other locales',
      (WidgetTester tester) async {
    // English (US English): 12-hour mode with AM/PM and 12-hour dial
    LocaleController.currentLocale.value = const Locale('en');
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains(' AM\n') == true ||
                widget.data?.contains(' PM\n') == true),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<DaylightAnalogClock>(find.byType(DaylightAnalogClock))
          .is24Hour,
      isFalse,
    );

    // Spanish: 24-hour mode without AM/PM and 24-hour dial
    LocaleController.currentLocale.value = const Locale('es');
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains(' AM\n') == true ||
                widget.data?.contains(' PM\n') == true),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<DaylightAnalogClock>(find.byType(DaylightAnalogClock))
          .is24Hour,
      isTrue,
    );
  });

  test('24-hour dial labels run from 0 to 23 and 12-hour labels from 1 to 12',
      () {
    final labels24 = ClockDialPainter.hourLabels(true);
    expect(labels24.length, 24);
    expect(labels24.first, '0');
    expect(labels24[12], '12');
    expect(labels24.last, '23');
    expect(labels24.contains('24'), isFalse);

    final labels12 = ClockDialPainter.hourLabels(false);
    expect(labels12.length, 12);
    expect(labels12.first, '1');
    expect(labels12.last, '12');
  });

  test('Hour hand angles match 24-hour (0 at top) and 12-hour dials', () {
    expect(
      ClockHandsPainter.hourHandAngle(0, 0, is24Hour: true),
      closeTo(0.0, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(6, 0, is24Hour: true),
      closeTo(pi / 2, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(12, 0, is24Hour: true),
      closeTo(pi, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(18, 0, is24Hour: true),
      closeTo(3 * pi / 2, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(15, 30, is24Hour: true),
      closeTo(15.5 * 2 * pi / 24, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(24, 0, is24Hour: true),
      closeTo(0.0, 1e-9),
    );

    expect(
      ClockHandsPainter.hourHandAngle(12, 0, is24Hour: false),
      closeTo(0.0, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(15, 0, is24Hour: false),
      closeTo(pi / 2, 1e-9),
    );
    expect(
      ClockHandsPainter.hourHandAngle(6, 0, is24Hour: false),
      closeTo(pi, 1e-9),
    );
  });

  test('LocalLocation.update marks location valid when coordinates arrive', () {
    final loc = LocalLocation();
    expect(loc.valid, isFalse);
    expect(loc.toString(), '<unknown location>');

    loc.update(LocationData.fromMap({'latitude': 37.77, 'longitude': -122.42}));
    expect(loc.valid, isTrue);
    expect(loc.latitude, closeTo(37.77, 1e-6));
    expect(loc.longitude, closeTo(-122.42, 1e-6));
    expect(loc.toString(), '(37.77, -122.42)');
  });

  test('LocalTime format produces 24h and 12h representation correctly', () {
    final lt = LocalTime();
    lt.hours = 14.5; // 14:30:00
    expect(lt.format(is24Hour: true), '14:30:00');
    expect(lt.format(is24Hour: false), '2:30:00 PM');

    lt.hours = 0.25; // 00:15:00
    expect(lt.format(is24Hour: true), '00:15:00');
    expect(lt.format(is24Hour: false), '12:15:00 AM');

    lt.hours = 12.0; // 12:00:00
    expect(lt.format(is24Hour: true), '12:00:00');
    expect(lt.format(is24Hour: false), '12:00:00 PM');

    lt.hours = 9.75; // 09:45:00
    expect(lt.format(is24Hour: true), '09:45:00');
    expect(lt.format(is24Hour: false), '9:45:00 AM');
  });

  test('formatDocumentHtml correctly parses HTML documents into readable text',
      () {
    const rawHtml = '''
<!DOCTYPE html>
<html>
<head><title>terms</title><style>.a{color:red;}</style></head>
<body>
<h1>Terms of Service &amp; Liability Disclaimer</h1>
<p>Last Updated: November 4, 2026</p>
<hr />
<h2>1. Acceptance of Terms</h2>
<p>By using the App, you agree to &ldquo;these terms&rdquo; &amp; conditions.</p>
<ul>
  <li><p>First bullet item with
multiple lines wrapped.</p></li>
  <li><p>Second bullet item</p></li>
</ul>
</body>
</html>
''';
    final result = formatDocumentHtml(rawHtml);
    expect(result.contains('<title>'), isFalse);
    expect(result.contains('terms Terms of Service'), isFalse);
    expect(
        result.startsWith('Terms of Service & Liability Disclaimer'), isTrue);
    expect(result.contains('&amp;'), isFalse);
    expect(result.contains('Last Updated: November 4, 2026'), isTrue);
    expect(result.contains('• First bullet item with multiple lines wrapped.'),
        isTrue);
    expect(result.contains('• Second bullet item'), isTrue);
    expect(result.contains('\n•\n'), isFalse);
    expect(result.contains('"these terms" & conditions.'), isTrue);
  });

  testWidgets(
      'Terms of Service dialog renders DocumentContent with live links and SelectionArea',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Open info popup menu
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Tap terms
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();

    // Dialog should display DocumentContent and SelectionArea
    expect(find.byType(DocumentContent), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);

    final textFinder = find.descendant(
      of: find.byType(DocumentContent),
      matching: find.byType(Text),
    );
    expect(textFinder, findsOneWidget);
    final Text textWidget = tester.widget(textFinder);
    final textSpan = textWidget.textSpan as TextSpan?;
    expect(textSpan, isNotNull);

    final plainText = textSpan!.toPlainText();
    expect(plainText.contains('&amp;'), isFalse);
    expect(plainText.contains('<title>'), isFalse);
    expect(plainText.contains('terms Terms of Service'), isFalse);
    expect(plainText.contains('Terms of Service'), isTrue);
    expect(plainText.contains('https://www.gchouse.org'), isTrue);

    // Verify live link exists with recognizer
    bool foundLiveLink = false;
    textSpan.visitChildren((span) {
      if (span is TextSpan &&
          span.text == 'https://www.gchouse.org' &&
          span.recognizer != null) {
        foundLiveLink = true;
      }
      return true;
    });
    expect(foundLiveLink, isTrue);
  });

  testWidgets(
      'About dialog renders main page text and live clickable links from info menu',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Open info popup menu
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    // Tap About
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentContent), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);

    final textFinder = find.descendant(
      of: find.byType(DocumentContent),
      matching: find.byType(Text),
    );
    expect(textFinder, findsOneWidget);
    final Text textWidget = tester.widget(textFinder);
    final textSpan = textWidget.textSpan as TextSpan?;
    expect(textSpan, isNotNull);

    final plainText = textSpan!.toPlainText();
    expect(plainText.contains('space-time continuum'), isTrue);
    expect(plainText.contains('tooth-to-tattoo ratio'), isTrue);
    expect(plainText.contains('www.gchouse.org'), isTrue);
    expect(plainText.contains('GitHub issues page'), isTrue);

    final liveLinkTexts = <String>{};
    textSpan.visitChildren((span) {
      if (span is TextSpan && span.recognizer != null && span.text != null) {
        liveLinkTexts.add(span.text!);
      }
      return true;
    });
    expect(
      liveLinkTexts,
      containsAll(['www.gchouse.org', 'GitHub', 'GitHub issues page']),
    );
  });

  testWidgets('Info menu and About dialog display app version number',
      (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'daylight',
      packageName: 'org.gchouse.daylight',
      version: '2.1.6',
      buildNumber: '3',
      buildSignature: '',
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('About v2.1.6+3'), findsOneWidget);

    await tester.tap(find.text('About v2.1.6+3'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('About v2.1.6+3'), findsOneWidget);
    expect(find.byType(DocumentContent), findsOneWidget);
  });

  test('All supported locales have compiled About HTML assets with links', () {
    for (final locale in LocaleController.supportedLocales) {
      final path = locale.languageCode == 'en'
          ? 'assets/about.html'
          : 'assets/about_${locale.languageCode}.html';
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      final segments = parseDocumentSegments(file.readAsStringSync());
      final urls = segments.where((s) => s.isLink).map((s) => s.url).toSet();
      expect(
        urls,
        containsAll([
          'https://www.gchouse.org',
          'https://github.com/fredgc/daylight',
          'https://github.com/fredgc/daylight/issues',
        ]),
        reason: '$path is missing expected links',
      );
    }
  });

  test('All supported locales have valid translations', () {
    for (final locale in LocaleController.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.appTitle.isNotEmpty, isTrue);
      expect(l10n.switchLanguageTooltip.isNotEmpty, isTrue);
    }
  });

  test('All localized ARB files maintain key parity with app_en.arb', () {
    final enContent = File('lib/l10n/app_en.arb').readAsStringSync();
    final enJson = jsonDecode(enContent) as Map<String, dynamic>;
    final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();

    final targetArbFiles = [
      'app_de.arb',
      'app_es.arb',
      'app_fr.arb',
      'app_ja.arb',
      'app_lt.arb',
      'app_pt.arb',
      'app_zh.arb',
    ];

    for (final file in targetArbFiles) {
      final content = File('lib/l10n/$file').readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      for (final key in enKeys) {
        expect(
          json.containsKey(key),
          isTrue,
          reason: 'ARB file $file is missing key "$key"',
        );
      }
    }
  });
}
