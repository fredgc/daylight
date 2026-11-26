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
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/l10n_extension.dart';
import 'location.dart';
import 'theme_controller.dart';
import 'time.dart';

class LocalClock extends StatefulWidget {
  const LocalClock({super.key});

  @override
  State<LocalClock> createState() => _LocalClockState();
}

class _LocalClockState extends State<LocalClock> {
  bool auto_update = true;
  LocalTime time = LocalTime();
  LocalLocation location = LocalLocation();

  String sub_text = "initial";
  Timer? short_timer;

  final TextEditingController debug_location = TextEditingController();
  final TextEditingController debug_time = TextEditingController();
  final TextEditingController debug_inc = TextEditingController();
  String error_string = "";
  String _appVersion = "";

  bool get is24HourMode {
    final current = LocaleController.currentLocale.value;
    final effective =
        (current != null && current != LocaleController.autoLocale)
            ? current
            : Localizations.localeOf(context);
    final isUSEnglish = effective.languageCode == 'en' &&
        (effective.countryCode == null ||
            effective.countryCode!.isEmpty ||
            effective.countryCode == 'US');
    return !isUSEnglish;
  }

  @override
  void initState() {
    super.initState();
    location.init();
    _loadAppVersion();
    LocaleController.currentLocale.addListener(_onLocaleChanged);

    short_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateTime();
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final ver = info.buildNumber.isNotEmpty
          ? '${info.version}+${info.buildNumber}'
          : info.version;
      if (mounted && ver.isNotEmpty) {
        setState(() {
          _appVersion = ver;
        });
      }
    } catch (_) {}
  }

  String _aboutLabel(BuildContext context) {
    final base = context.l10n.aboutTitle;
    return _appVersion.isNotEmpty ? '$base v$_appVersion' : base;
  }

  void _onLocaleChanged() {
    if (mounted) {
      updateTime();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateTime();
  }

  @override
  void dispose() {
    LocaleController.currentLocale.removeListener(_onLocaleChanged);
    super.dispose();
    short_timer?.cancel();
    debug_location.dispose();
    debug_time.dispose();
    debug_inc.dispose();
    location.dispose();
  }

  void updateTime() {
    if (auto_update) {
      time.update(DateTime.now(), location);
    } else {
      int increment = int.tryParse(debug_inc.text) ?? 0;
      if (increment > 0) {
        // For debugging.
        time.increment(increment, location);
      }
    }
    final is24Hour = mounted ? is24HourMode : true;
    String timeS = time.format(is24Hour: is24Hour);
    String locS = location.valid
        ? "(${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)})"
        : (mounted ? context.l10n.unknownLocation : location.toString());
    setState(() {
      sub_text = ("$timeS\n$locS");
    });
  }

  void startDebug() {
    setState(() {
      auto_update = false;
      debug_time.text = time.debugString();
      debug_location.text = location.toString();
      debug_inc.text = "0";
    });
  }

  void endDebug() {
    setState(() {
      auto_update = true;
      location.refresh();
    });
  }

  void toggleDebug() {
    if (auto_update) {
      startDebug();
    } else {
      endDebug();
    }
  }

  void transport() {
    print("Transport!");
    try {
      error_string = "";
      location.transport(debug_location.text);
      time.transport(debug_time.text, location);
    } catch (ex) {
      error_string = "$ex";
    }
    updateTime();
  }

  void _showDocumentDialog(
      BuildContext context, String assetName, String title) {
    final documentFuture = loadLocalizedHtmlAsset(context, assetName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(dialogContext).width * 0.85, 560),
          child: FutureBuilder<String>(
            future: documentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final text = snapshot.data ?? '';
              return SingleChildScrollView(
                child: DocumentContent(html: text),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.closeButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (auto_update) {
      body = clock(context);
    } else {
      body = OrientationBuilder(
        builder: (context, orientation) {
          List<Widget> children = [
            clock(context),
            Expanded(child: debugControls(context)),
          ];
          if (orientation == Orientation.portrait) {
            return Column(children: children);
          } else {
            return Row(children: children);
          }
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.currentThemeMode,
            builder: (context, themeMode, _) {
              final icon = switch (themeMode) {
                ThemeMode.dark => Icons.dark_mode_outlined,
                ThemeMode.light => Icons.light_mode_outlined,
                ThemeMode.system => Icons.brightness_auto_outlined,
              };
              return PopupMenuButton<ThemeMode>(
                icon: Icon(icon),
                tooltip: context.l10n.switchThemeTooltip,
                initialValue: themeMode,
                onSelected: ThemeController.setThemeMode,
                itemBuilder: (context) => [
                  CheckedPopupMenuItem<ThemeMode>(
                    value: ThemeMode.system,
                    checked: themeMode == ThemeMode.system,
                    child: Text(context.l10n.themeSystem),
                  ),
                  CheckedPopupMenuItem<ThemeMode>(
                    value: ThemeMode.light,
                    checked: themeMode == ThemeMode.light,
                    child: Text(context.l10n.themeLight),
                  ),
                  CheckedPopupMenuItem<ThemeMode>(
                    value: ThemeMode.dark,
                    checked: themeMode == ThemeMode.dark,
                    child: Text(context.l10n.themeDark),
                  ),
                ],
              );
            },
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language_rounded),
            tooltip: context.l10n.switchLanguageTooltip,
            initialValue: LocaleController.currentLocale.value ??
                LocaleController.autoLocale,
            onSelected: (loc) {
              LocaleController.setLocale(loc);
              updateTime();
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<Locale>(
                value: LocaleController.autoLocale,
                checked: LocaleController.currentLocale.value == null,
                child: Text(context.l10n.languageAuto),
              ),
              for (final locale in LocaleController.supportedLocales)
                CheckedPopupMenuItem<Locale>(
                  value: locale,
                  checked: LocaleController.currentLocale.value?.languageCode ==
                      locale.languageCode,
                  child: Text(LocaleController.languageDisplayName(locale)),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.info_outline),
            tooltip: context.l10n.aboutTitle,
            onSelected: (value) {
              if (value == 'about') {
                _showDocumentDialog(context, 'about', _aboutLabel(context));
              } else if (value == 'privacy') {
                _showDocumentDialog(
                    context, 'privacy', context.l10n.privacyPolicyTitle);
              } else if (value == 'terms') {
                _showDocumentDialog(
                    context, 'terms', context.l10n.termsOfServiceTitle);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'about',
                child: Text(_aboutLabel(context)),
              ),
              PopupMenuItem<String>(
                value: 'privacy',
                child: Text(context.l10n.privacyPolicyTitle),
              ),
              PopupMenuItem<String>(
                value: 'terms',
                child: Text(context.l10n.termsOfServiceTitle),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget clock(BuildContext context) {
    final is24Hour = is24HourMode;

    return Semantics(
      label: context.l10n.clockFaceSemantics,
      child: GestureDetector(
        onDoubleTap: () {
          toggleDebug();
        },
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DaylightAnalogClock(
              hour: time.hour,
              minute: time.minute,
              second: time.second,
              secondsPerMinute: time.seconds_per_minute,
              is24Hour: is24Hour,
              child: clockReadout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget clockReadout(BuildContext context) {
    final is24Hour = is24HourMode;
    final timeS = time.format(is24Hour: is24Hour);
    final locS = location.valid
        ? "(${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)})"
        : (mounted ? context.l10n.unknownLocation : location.toString());
    final displayText = "$timeS\n$locS";

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: colorScheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Align(
        alignment: const FractionalOffset(0.5, 0.75),
        child: Text(
          displayText,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget debugControls(BuildContext context) {
    return ListView(
      children: <Widget>[
        Text(
          error_string,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        TextField(
          controller: debug_location,
          onSubmitted: (value) {
            transport();
          },
          style: const TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: context.l10n.locationHint,
          ),
        ),
        TextField(
          controller: debug_time,
          onSubmitted: (value) {
            transport();
          },
          style: const TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: context.l10n.dateTimeHint,
          ),
        ),
        TextField(
          controller: debug_inc,
          style: const TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: context.l10n.incrementSpeedHint,
          ),
        ),
        IconButton(
          onPressed: transport,
          icon: const Icon(Icons.drive_file_move_outline),
          tooltip: context.l10n.transportTooltip,
          iconSize: 16,
        ),
      ],
    );
  }
}

/// Analog clock supporting both 12-hour (1-12) and 24-hour (0-23) dials
/// with a variable-speed second hand.
class DaylightAnalogClock extends StatelessWidget {
  final int hour;
  final int minute;
  final int second;
  final int secondsPerMinute;
  final bool is24Hour;
  final Widget? child;

  const DaylightAnalogClock({
    super.key,
    required this.hour,
    required this.minute,
    required this.second,
    required this.secondsPerMinute,
    required this.is24Hour,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dialColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLowest;
    final foregroundColor = colorScheme.onSurface;

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: ClockDialPainter(
          is24Hour: is24Hour,
          dialColor: dialColor,
          markingColor: foregroundColor,
          hourNumberColor: foregroundColor,
        ),
        foregroundPainter: ClockHandsPainter(
          hour: hour,
          minute: minute,
          second: second,
          secondsPerMinute: secondsPerMinute,
          is24Hour: is24Hour,
          handColor: foregroundColor,
        ),
        child: child,
      ),
    );
  }
}

/// Paints the analog clock dial, tick markings, and hour numbers.
class ClockDialPainter extends CustomPainter {
  final bool is24Hour;
  final Color dialColor;
  final Color markingColor;
  final Color hourNumberColor;

  const ClockDialPainter({
    required this.is24Hour,
    this.dialColor = Colors.white,
    this.markingColor = Colors.black,
    this.hourNumberColor = Colors.black,
  });

  static const List<String> hourNumbers12 = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
  ];

  static const List<String> hourNumbers24 = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
  ];

  static List<String> hourLabels(bool is24Hour) =>
      is24Hour ? hourNumbers24 : hourNumbers12;

  @override
  void paint(Canvas canvas, Size size) {
    final double clockRadius = min(size.width, size.height) / 2;
    canvas.translate(size.width / 2, size.height / 2);

    canvas.drawCircle(
      Offset.zero,
      clockRadius,
      Paint()
        ..isAntiAlias = true
        ..color = dialColor
        ..style = PaintingStyle.fill,
    );

    final double innerRadius = _drawMarkings(canvas, clockRadius);
    final double hourNumberRadius = innerRadius * 0.85;
    _drawHourNumbers(canvas, hourNumberRadius);
  }

  double _drawMarkings(Canvas canvas, double radius) {
    final double markingRadius = radius * 0.95;
    final double smallMarkingWidth = (radius - markingRadius) / 1.5;
    final double bigMarkingWidth = radius - markingRadius;

    final List<Offset> smallMarkings = [];
    final List<Offset> bigMarkings = [];

    if (is24Hour) {
      for (int i = 0; i < 24; i++) {
        final double angle = i * 2 * pi / 24;
        final Offset pt = Offset(
          sin(angle) * markingRadius,
          -cos(angle) * markingRadius,
        );
        if (i % 2 == 0) {
          bigMarkings.add(pt);
        } else {
          smallMarkings.add(pt);
        }
      }
    } else {
      for (int i = 0; i < 60; i++) {
        final double angle = i * 2 * pi / 60;
        final Offset pt = Offset(
          sin(angle) * markingRadius,
          -cos(angle) * markingRadius,
        );
        if (i % 5 == 0) {
          bigMarkings.add(pt);
        } else {
          smallMarkings.add(pt);
        }
      }
    }

    canvas.drawPoints(
      PointMode.points,
      smallMarkings,
      Paint()
        ..isAntiAlias = true
        ..color = markingColor
        ..strokeWidth = smallMarkingWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPoints(
      PointMode.points,
      bigMarkings,
      Paint()
        ..isAntiAlias = true
        ..color = markingColor
        ..strokeWidth = bigMarkingWidth
        ..strokeCap = StrokeCap.round,
    );

    return markingRadius - bigMarkingWidth / 2;
  }

  void _drawHourNumbers(Canvas canvas, double radius) {
    final labels = hourLabels(is24Hour);
    final int count = labels.length;
    final double fontSize = is24Hour ? radius / 7.5 : radius / 4.0;

    for (int i = 0; i < count; i++) {
      // For 24-hour mode, index 0 ('0') is at top (angle 0).
      // For 12-hour mode, index 0 ('1') is at 1 o'clock and index 11 ('12') is at top.
      final int position = is24Hour ? i : (i + 1) % count;
      final double angle = position * 2 * pi / count;
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: fontSize, color: hourNumberColor),
        ),
      )..layout();

      final double x = sin(angle) * radius;
      final double y = -cos(angle) * radius;
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ClockDialPainter oldDelegate) {
    return oldDelegate.is24Hour != is24Hour ||
        oldDelegate.dialColor != dialColor ||
        oldDelegate.markingColor != markingColor ||
        oldDelegate.hourNumberColor != hourNumberColor;
  }
}

/// Paints the hour, minute, and variable-speed second hands and center point.
class ClockHandsPainter extends CustomPainter {
  final int hour;
  final int minute;
  final int second;
  final int secondsPerMinute;
  final bool is24Hour;
  final Color handColor;

  const ClockHandsPainter({
    required this.hour,
    required this.minute,
    required this.second,
    required this.secondsPerMinute,
    required this.is24Hour,
    this.handColor = Colors.black,
  });

  /// Returns the clockwise angle in radians from the top of the dial (0 = top).
  static double hourHandAngle(int hour, int minute, {required bool is24Hour}) {
    if (is24Hour) {
      return ((hour % 24) + minute / 60.0) * 2 * pi / 24;
    }
    return ((hour % 12) + minute / 60.0) * 2 * pi / 12;
  }

  static double minuteHandAngle(int minute) {
    return (minute % 60) * 2 * pi / 60;
  }

  static double secondHandAngle(int second, int secondsPerMinute) {
    if (secondsPerMinute <= 0) return 0.0;
    return second * 2 * pi / secondsPerMinute;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double clockRadius = min(size.width, size.height) / 2;
    final double markingRadius = clockRadius * 0.95;
    final double bigMarkingWidth = clockRadius - markingRadius;
    final double hourNumberRadius =
        (markingRadius - bigMarkingWidth / 2) * 0.85;

    canvas.translate(size.width / 2, size.height / 2);

    final double hourLength = hourNumberRadius * 0.75;
    final double hourWidth = hourLength * 0.09;
    final double minuteLength = hourNumberRadius;
    final double minuteWidth = hourNumberRadius * 0.03;
    final double secondLength = clockRadius * 0.85;
    const double secondWidth = 1.5;

    _drawHand(
      canvas,
      hourHandAngle(hour, minute, is24Hour: is24Hour),
      hourLength,
      hourWidth,
    );
    _drawHand(
      canvas,
      minuteHandAngle(minute),
      minuteLength,
      minuteWidth,
    );
    _drawHand(
      canvas,
      secondHandAngle(second, secondsPerMinute),
      secondLength,
      secondWidth,
    );

    canvas.drawPoints(
      PointMode.points,
      [Offset.zero],
      Paint()
        ..isAntiAlias = true
        ..color = handColor
        ..strokeWidth = hourWidth * 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawHand(Canvas canvas, double angle, double length, double width) {
    final Offset tip = Offset(sin(angle) * length, -cos(angle) * length);
    canvas.drawLine(
      Offset.zero,
      tip,
      Paint()
        ..isAntiAlias = true
        ..color = handColor
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant ClockHandsPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.second != second ||
        oldDelegate.secondsPerMinute != secondsPerMinute ||
        oldDelegate.is24Hour != is24Hour ||
        oldDelegate.handColor != handColor;
  }
}

class DocumentContent extends StatefulWidget {
  final String html;

  const DocumentContent({super.key, required this.html});

  @override
  State<DocumentContent> createState() => _DocumentContentState();
}

class _DocumentContentState extends State<DocumentContent> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final segments = parseDocumentSegments(widget.html);
    final theme = Theme.of(context);
    final linkColor = theme.colorScheme.primary;

    final spans = <InlineSpan>[];
    for (final segment in segments) {
      if (segment.isLink) {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => _launch(segment.url!);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: segment.text,
            style: TextStyle(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
            mouseCursor: SystemMouseCursors.click,
            recognizer: recognizer,
          ),
        );
      } else {
        spans.add(TextSpan(text: segment.text));
      }
    }

    return SelectionArea(
      child: Text.rich(
        TextSpan(
          style: theme.textTheme.bodyMedium,
          children: spans,
        ),
      ),
    );
  }
}
