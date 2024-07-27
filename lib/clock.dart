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
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_analog_clock/flutter_analog_clock.dart';
import 'package:intl/intl.dart';

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
  final DateFormat time_format = DateFormat.jm();

  final TextEditingController debug_location = TextEditingController();
  final TextEditingController debug_time = TextEditingController();
  final TextEditingController debug_inc = TextEditingController();
  String error_string = "";

  @override initState() {
    // print("Clock State initialize. -=========================================");
    // print("init Location valid = $location.valid");
    super.initState();
    location.init();

    short_timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) { updateTime(); }
    );
  }

  @override dispose() {
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
      int increment = int.parse(debug_inc.text);
      if (increment > 0) {
        // For debugging.
        time.increment(increment, location);
      }
    }
    DateTime now = time.getTime();
    _analogClockKey.currentState!.dateTime = now;
    String time_s = time.toString();
    String loc_s = location.toString();
    setState(() {
        sub_text = ("$time_s\n" + "$loc_s");
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
    if(auto_update) {
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
    } catch(ex) {
      error_string = "$ex";
    }
    updateTime();
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
          if(orientation == Orientation.portrait) {
            return Column(children: children);
          } else {
            return Row(children: children);
          }
        },
      );
    }
    return Scaffold(
      body: SafeArea(child: body),
    );
  }

  // @override
  Widget build_grid_view(BuildContext context) {
    Widget body;
    if (auto_update) {
      body = clock(context);
    } else {
      body = OrientationBuilder(
        builder: (context, orientation) {
          return GridView.count(
            crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
            children: [ clock(context), debugControls(context), ],
          );
        },
      );
    }
    return Scaffold(
      body: SafeArea(child: body),
    );
  }

  Widget clock(BuildContext context) {
    return GestureDetector( 
      // onTap: () { 
      //   print("On Tap. -----------------------");
      // },
      onDoubleTap: () { 
        // print("On Double Tap. -----------------------");
        toggleDebug();
      },
      child: Container(
        child: Align(
          alignment: Alignment.center, 
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnalogClock(
              key: _analogClockKey,
              secondHandLengthFactor: 0, // I'll draw my own.
              dateTime: time.getTime(),
              isKeepTime: false,
              child: secondHand(context),
            ),
          ),
        ),
      ),
    );
  }
  Widget secondHand(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: <Widget>[
          Align(
            alignment: FractionalOffset(0.5, 0.75),
            child: Text(sub_text,
              style: TextStyle(fontSize: 12,
                // color: Colors.green,
            ),
              textAlign: TextAlign.center),
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
        Text(error_string,
          style: TextStyle(
            fontSize: 10,
            color: Colors.red,
          ),
        ),
        TextField(
          controller: debug_location,
          onSubmitted: (value) { transport(); },
          style: TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: "Location",
        )),
        TextField(
          controller: debug_time,
          onSubmitted: (value) { transport(); },
          style: TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: "Date/Time",
        )),
        TextField(
          controller: debug_inc,
          style: TextStyle(fontSize: 10),
          decoration: InputDecoration(
            hintText: "Increment Speed",
        )),
        IconButton(
          onPressed: transport,
          icon: Icon(Icons.drive_file_move_outline),
          tooltip: "Transport",
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
    // print("Second hand angle = ${angle.toStringAsFixed(3)} = ${second}/${seconds_per_minute}");
    Offset center = Offset.zero;
    // angle is clockwise, starting from top.
    Offset tip = Offset(radius*sin(angle), -radius*cos(angle));
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
