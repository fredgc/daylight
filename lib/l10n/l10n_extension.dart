import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

class LocaleController {
  static const String _keyLocale = 'app_locale';
  static const Locale autoLocale = Locale('auto');
  static final ValueNotifier<Locale?> currentLocale =
      ValueNotifier<Locale?>(null);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('fr'),
    Locale('ja'),
    Locale('lt'),
    Locale('pt'),
    Locale('zh'),
  ];

  static String languageDisplayName(Locale? locale) {
    if (locale == null) return 'System Default';
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'ja':
        return '日本語';
      case 'lt':
        return 'Lietuvių';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文 (简体)';
      default:
        return locale.toLanguageTag();
    }
  }

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_keyLocale);
      if (code != null && code.isNotEmpty) {
        currentLocale.value = Locale(code);
      }
    } catch (_) {}
  }

  static Future<void> setLocale(Locale? locale) async {
    final effective = (locale == null ||
            locale == autoLocale ||
            locale.languageCode == 'auto')
        ? null
        : locale;
    currentLocale.value = effective;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (effective == null) {
        await prefs.remove(_keyLocale);
      } else {
        await prefs.setString(_keyLocale, effective.languageCode);
      }
    } catch (_) {}
  }
}

Future<String> loadLocalizedHtmlAsset(
    BuildContext context, String baseName) async {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale != 'en') {
    try {
      return await rootBundle.loadString('assets/${baseName}_$locale.html');
    } catch (_) {
      // Fall back to default English document
    }
  }
  return await rootBundle.loadString('assets/$baseName.html');
}

class DocumentSegment {
  final String text;
  final String? url;

  const DocumentSegment(this.text, [this.url]);

  bool get isLink => url != null && url!.isNotEmpty;
}

/// Parses raw compiled document HTML into structured plain text and link segments.
List<DocumentSegment> parseDocumentSegments(String html) {
  var text = html;
  text = text.replaceAll(
      RegExp(r'<head[\s\S]*?</head>', caseSensitive: false), '');
  text = text.replaceAll(
      RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
  text = text.replaceAll(
      RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '');

  text = text.replaceAll(
      RegExp(r'<li[^>]*>\s*(?:<p[^>]*>)?', caseSensitive: false), '\n\n• ');
  text = text.replaceAll(RegExp(r'</p>\s*</li>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

  text = text.replaceAll(
      RegExp(r'<(h[1-6]|p|div|section|article|header|footer)[^>]*>',
          caseSensitive: false),
      '\n\n');
  text = text.replaceAll(
      RegExp(r'</(h[1-6]|p|div|section|article|header|footer)>',
          caseSensitive: false),
      '\n\n');
  text =
      text.replaceAll(RegExp(r'<(hr|br)[^>]*>', caseSensitive: false), '\n\n');

  text = text.replaceAllMapped(
    RegExp(r'<a\s+[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</a>',
        caseSensitive: false),
    (match) => '\u0000${match.group(1)}\u0001${match.group(2)}\u0000',
  );

  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  text = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&ldquo;', '"')
      .replaceAll('&rdquo;', '"')
      .replaceAll('&lsquo;', "'")
      .replaceAll('&rsquo;', "'")
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–')
      .replaceAll('&nbsp;', ' ');

  final paragraphs = text.split(RegExp(r'\n\s*\n'));
  final cleaned = <String>[];
  for (final p in paragraphs) {
    final lines = p
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .where((l) => l.isNotEmpty);
    if (lines.isNotEmpty) {
      cleaned.add(lines.join(' '));
    }
  }
  final fullText = cleaned.join('\n\n').trim();

  final linkPattern = RegExp(r'\u0000([^\u0001]*)\u0001([^\u0000]*)\u0000');
  final segments = <DocumentSegment>[];
  int lastEnd = 0;
  for (final match in linkPattern.allMatches(fullText)) {
    if (match.start > lastEnd) {
      segments.add(DocumentSegment(fullText.substring(lastEnd, match.start)));
    }
    final url = match.group(1) ?? '';
    final linkText = match.group(2) ?? '';
    segments.add(DocumentSegment(linkText, url));
    lastEnd = match.end;
  }
  if (lastEnd < fullText.length) {
    segments.add(DocumentSegment(fullText.substring(lastEnd)));
  }
  return segments;
}

/// Converts raw compiled document HTML into cleanly formatted, human-readable
/// plain text suitable for SelectableText. Strips head/title/style blocks,
/// converts headings, paragraphs, and list items into structured text with
/// line breaks, unwraps intra-paragraph lines, and decodes HTML entities.
String formatDocumentHtml(String html) {
  return parseDocumentSegments(html).map((s) => s.text).join('');
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
