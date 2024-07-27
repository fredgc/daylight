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

import 'package:intl/intl.dart';

import 'location.dart';

class LocalTime {
  final DateFormat debug_format = DateFormat.yMMMMd().add_Hms();
  DateTime input = DateTime.now();

  double hours = 0.0;
  int seconds_per_minute = 60;  // How many seconds per minute.
  double longitude = 0.0;
  double latitude = 0.0;
  int local_day = 0;            // Days since 1/1/2000.
  static final double s_per_day = 60*60*24;
  double sunrise = 0.25 * s_per_day;
  double noon = 0.5 * s_per_day;
  double sunset = 0.75 * s_per_day;
  static final double tolerance = 0.1;

  int get hour { return hours.floor(); }
  int get minute { return (hours * 60).floor() % 60; }
  int get second {
    if (seconds_per_minute < 1) return 0;
    return (hours*60*seconds_per_minute).floor() % seconds_per_minute;
  }

  // Initialize the clock.
  LocalTime() {
  }

  // Convert to a string, for printing and debugging.
  String toString() {
    return (hour.toString().padLeft(2, '0'))
    + ":" + (minute.toString().padLeft(2, '0'))
    + ":" + (second.toString().padLeft(2, '0'));
  }

  // Convert to a string, for printing and debugging.
  String debugString() {
    return debug_format.format(input);
  }

  // Set time manually, for debugging. Might throw a Parse exception.
  void transport(String date_time, LocalLocation location) {
    update( debug_format.parse(date_time), location);
  }

  void increment(int increment, LocalLocation location) {
    update(input.add(Duration(seconds: increment)), location);
  }

  // Set the time based on a date. Usually from a timer.
  void update(DateTime now, LocalLocation location) {
    this.input = now;
    // Just for debugging.
    hours = now.hour + (now.minute + now.second / 60.0) / 60.0;
    bool recompute_sunrise = false;
    if ( (longitude - location.longitude).abs() > tolerance
      || (latitude - location.latitude).abs() > tolerance) {
      // print("loc (${longitude}, ${latitude}) -> (${location.longitude}, ${location.latitude}) ");
      longitude = location.longitude;
      latitude = location.latitude;
      recompute_sunrise = true;
    }

    // https://en.wikipedia.org/wiki/Sunrise_equation
    // Julian day = day since Jan 1st, 2000, noon.  UTC, including leap seconds
    // JD = Julian Date = days since beginning of history.
    // time = unix time = milliseconds since 1970.
    // time = (JD − 2440587.5) × 86400
    // jd = time/86400 + 2440587.5
    // n = time/86400 + 2440587.5 - 2451545 + 0.0008
    // n = time/86400 - 10957.5 + 0.0008
    // m2d = milliseconds / day.
    double unix_day = now.millisecondsSinceEpoch/(1000.0 * s_per_day);
    double julian_day = unix_day - 10957.5 + 0.0008;
    // local day = mean solar noon, since 1/1/2000, noon.
    double time_zone = 24.0 * longitude / 360.0;  // Just for debugging.
    double local_day = julian_day + longitude / 360.0;
    if (local_day.floor() != this.local_day) {
      recompute_sunrise = true;
      this.local_day = local_day.floor();
      // print("New day ${this.local_day}");
    }
    // Convert to seconds after midnight, instead of after noon.
    // local_time = seconds since beginning of day, i.e. midnight.
    double local_time = ((local_day - 0.5) * s_per_day).floor() % s_per_day;

    // print("day = $local_day, loc=($longitude, $latitude), "
    //   + "local_time = ${log_time(local_time)}, day = ${local_day.floor()}");

    if(recompute_sunrise) {
      find_sunrise(local_day);
    }
    hours = 0;
    if (local_time < sunrise) {
      // print("Early: ${log_time(local_time)} < ${log_time(sunrise)}");
      hours = interpolate(sunrise, local_time);
    } else if (local_time < noon) {
      // print("Morning:  ${log_time(sunrise)} < ${log_time(local_time)} < ${log_time(noon)}");
      hours = 12 - interpolate(noon-sunrise, noon-local_time);
    } else if (local_time < sunset) {
      // print("Afternoon:  ${log_time(noon)} < ${log_time(local_time)} < ${log_time(sunset)}");
      hours = 12 + interpolate(sunset-noon, local_time-noon);
    } else {
      // print("Evening:  ${log_time(sunset)} < ${log_time(local_time)}");
      hours = 24 - interpolate(s_per_day - sunset, s_per_day - local_time);
    }

  }

  void find_sunrise(double local_day) {
    // Solar mean anomaly.
    double mean = (357.5291 + 0.98560028 * local_day).floor() % 360;
    double center
        = 1.9148 * sin(pi / 180.0 * (    mean))
        + 0.0200 * sin(pi / 180.0 * (2 * mean))
        + 0.0003 * sin(pi / 180.0 * (3 * mean));
    // lambda = Ecliptic longitude. argument of perihelion = 102.9372
    double lambda = (mean + center + 180 + 102.9372).floor() % 360;

    // Solar Transit = hour angle for solar transit, or solar noon. (in seconds)
    noon = (0.5 +  (0.0053*sin(pi / 180.0 * mean)
            - 0.0069 * sin(pi / 180.0 * 2*lambda))) * s_per_day;

    // Declinaition of the sun:
    final double sin_ecliptic = sin(pi / 180.0 * 23.44);
    double sin_d = sin(pi / 180.0 * lambda) * sin_ecliptic;
    double cos_d = sqrt(1 - sin_d*sin_d);
    // Hour angle cos(omega) = sin(-0.83) - sin(lat)*sin_d / (cos(lat) * cos_d),
    // but let's protect from divide by zero.  If cos(omega) will be huge, we
    // want to find its sign so we can chop it at 1 or -1.
    double numerator = sin(pi / 180.0 * (-0.83))
        - sin(pi / 180.0 * latitude) * sin_d;
    double denominator = cos_d * cos(pi / 180.0 * latitude);
    // Notice that declination and latitude are <= 90 degrees, so
    // denominator >= 0, so num/den > 1 is equivalent to num > den.
    double omega = 0;  // difference between suset and noon.
    if (numerator > denominator) {
      // cos(omega) > 1.
      omega = 0;
    } else if (-numerator > denominator) {
      omega = 0.5;
    } else {
      omega = 0.5*acos(numerator/denominator) / pi;
    }
    sunrise = noon - omega*s_per_day;
    sunset = noon + omega*s_per_day;

    print("sunrise=${log_time(sunrise)}, noon=${log_time(noon)}, "
      + "sunset=${log_time(sunset)}");
  }

  // Interpolate for time between 0 and real, in seconds, and return an hour
  // between 0 and 6.  This also updates seconds_per_minute.
  double interpolate(double real, double time) {
    if (time <= 0.0) return 0.0;
    // We interpolate from f : [0, real] to [0, clock].
    // real = real time of event (seconds).  clock = clock time of event.
    double clock = s_per_day/4.0;
    if (real <= time) return clock;
    double alpha = real/clock;
    // We do this by find g(y) and setting f(x) = c * g(x/r).
    // We want f(0) = 0, f(r) = c, f'(r) = 1.  f''(0) = 0.
    // Which becomes g(0) = 0, g(1) = 1, g'(1) = alpha, g''(0) = 0.
    // Some linear algebra gives us:
    // g(y) = ( alpha-1)/2.0 * y^3 + (3-alpha)/2.0 * y
    double y = time/real;
    double g = (alpha-1)/2.0 * y*y*y + (3-alpha)/2.0 * y;
    double f = clock * g;
    // solves g(0) = 0, g(1) = 1, g'(1) = alpha, g''(0) = 0.
    // Finally, f' = clock speed = number of seconds per hour.
    // f'(x) = g'(y)/alpha = (3*( alpha-1)/2.0 * y^2 + (3-alpha)/2.0);
    double gp = 3*(alpha-1)/2.0*y*y + (3-alpha)/2.0;
    double fp = gp / alpha;  // sec/sec.
    int seconds_per_minute = (60.0 / fp).floor();
    if (this.seconds_per_minute != seconds_per_minute) {
      print("seconds_per_minute = $seconds_per_minute");
    }
    this.seconds_per_minute = seconds_per_minute;
    return f * 24 / s_per_day;
  }

  // Get the local time, based on a recent call to transport or update.
  DateTime getTime() {
    int scaled_seconds = (second * 60.0 / seconds_per_minute).round();
    return DateTime(1964, 04, 21, hour, minute, scaled_seconds);
  }

  String log_time(double time) {
    bool negative = false;
    if (time < 0) {
      negative = true;
      time = -time;
    }
    int h = (time/3600).floor();
    int m = (time/60).floor() % 60;
    int s = (time).floor() % 60;
    return (negative ? "-" : "+") + (h.toString().padLeft(2, '0'))
    + ":" + (m.toString().padLeft(2, '0'))
    + ":" + (s.toString().padLeft(2, '0'));
  }

}
