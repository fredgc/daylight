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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daylight/clock.dart';
import 'package:daylight/l10n/l10n_extension.dart';
import 'package:daylight/main.dart';
import 'package:daylight/time.dart';

void main() {
  setUp(() {
    LocaleController.currentLocale.value = null;
  });

  testWidgets('LocalClock smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LocalClock), findsOneWidget);
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
    // English (US English): 12-hour mode with AM/PM
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

    // Spanish: 24-hour mode without AM/PM
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
