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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/l10n_extension.dart';
import 'location.dart';
import 'time.dart';

class LocalClock extends StatefulWidget {
  const LocalClock({super.key});

  @override
  State<LocalClock> createState() => _LocalClockState();
}

class _LocalClockState extends State<LocalClock> {
  final GlobalKey<AnalogClockState> _analogClockKey = GlobalKey();
  bool auto_update = true;
  LocalTime time = LocalTime();
  LocalLocation location = LocalLocation();

  String sub_text = "initial";
  Timer? short_timer;

  final TextEditingController debug_location = TextEditingController();
  final TextEditingController debug_time = TextEditingController();
  final TextEditingController debug_inc = TextEditingController();
  String error_string = "";

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
    LocaleController.currentLocale.addListener(_onLocaleChanged);

    short_timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateTime();
    });
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
    DateTime now = time.getTime();
    _analogClockKey.currentState?.dateTime = now;
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(dialogContext).width * 0.85, 560),
          child: FutureBuilder<String>(
            future: loadLocalizedHtmlAsset(context, assetName),
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
            tooltip: context.l10n.termsOfServiceTitle,
            onSelected: (value) {
              if (value == 'privacy') {
                _showDocumentDialog(
                    context, 'privacy', context.l10n.privacyPolicyTitle);
              } else if (value == 'terms') {
                _showDocumentDialog(
                    context, 'terms', context.l10n.termsOfServiceTitle);
              }
            },
            itemBuilder: (context) => [
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
    final List<String> hourNumbers = is24Hour && time.hour >= 12
        ? const [
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
            '24'
          ]
        : const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];

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
            child: AnalogClock(
              key: _analogClockKey,
              secondHandLengthFactor: 0, // I'll draw my own.
              dateTime: time.getTime(),
              isKeepTime: false,
              hourNumbers: hourNumbers,
              child: secondHand(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget secondHand(BuildContext context) {
    final is24Hour = is24HourMode;
    final timeS = time.format(is24Hour: is24Hour);
    final locS = location.valid
        ? "(${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)})"
        : (mounted ? context.l10n.unknownLocation : location.toString());
    final displayText = "$timeS\n$locS";

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: const FractionalOffset(0.5, 0.75),
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          CustomPaint(
            painter: HandPainter(time.second, time.seconds_per_minute),
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget debugControls(BuildContext context) {
    return ListView(
      children: <Widget>[
        Text(
          error_string,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.red,
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

// Paint the second hand, based on the time.
class HandPainter extends CustomPainter {
  int second;
  int seconds_per_minute;
  double length = 0.85;
  HandPainter(this.second, this.seconds_per_minute);

  @override
  void paint(Canvas canvas, Size size) {
    // translate to center of clock
    canvas.translate(size.width / 2, size.height / 2);
    double radius = length * size.width / 2;
    double angle = second * pi * 2 / seconds_per_minute;
    Offset center = Offset.zero;
    // angle is clockwise, starting from top.
    Offset tip = Offset(radius * sin(angle), -radius * cos(angle));
    var paint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, tip, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
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
