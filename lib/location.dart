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
import 'package:location/location.dart';

class LocalLocation {
  double latitude = 0.0;
  double longitude = 0.0;

  Location location = Location();
  StreamSubscription? listener;
  bool valid = false;
  bool auto_update = true;

  // Initialize the location service.
  void init() async {
    await refresh();
  }

  void dispose() async {
    await listener?.cancel();
  }

  // Refresh the location from the service, if possible.
  // Also, turn on auto update.
  Future<void> refresh() async {
    auto_update = true;

    await listener?.cancel();
    location = Location();

    try {
      await location.changeSettings(accuracy: LocationAccuracy.low);
    } catch (_) {}

    // On web, location_web 6.0.1's hasPermission() passes a JSBoxedDartObject
    // to navigator.permissions.query() which throws a TypeError. Calling
    // getLocation() directly triggers the browser geolocation prompt.
    if (!kIsWeb) {
      try {
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            return;
          }
        }
        PermissionStatus permission = await location.hasPermission();
        if (permission == PermissionStatus.denied) {
          permission = await location.requestPermission();
          if (permission != PermissionStatus.granted &&
              permission != PermissionStatus.grantedLimited) {
            return;
          }
        }
      } catch (e) {
        debugPrint("Location permission/service check failed: $e");
        return;
      }
    }

    try {
      LocationData data = await location.getLocation();
      update(data);
    } catch (e) {
      debugPrint("getLocation failed: $e");
    }

    try {
      listener = location.onLocationChanged.listen(
        (LocationData data) {
          update(data);
        },
        onError: (Object error) {
          debugPrint("Location stream error: $error");
        },
      );
    } catch (e) {
      debugPrint("onLocationChanged failed: $e");
    }
  }

  // Convert the location to a string, for display or debug.
  @override
  String toString() {
    if (valid) {
      return "(${latitude.toStringAsFixed(2)}, "
          "${longitude.toStringAsFixed(2)})";
    }
    return "<unknown location>";
  }

  // Parse the string into a location, for debugging.
  // Also, turn off auto update.
  // Might throw a Parse exception.
  void transport(String locationString) {
    auto_update = false;
    // Trim off extra characters (whitespace and parentheses), and
    // split by the comma.
    locationString = locationString.replaceAll(' ', '');
    locationString = locationString.replaceAll('(', '');
    locationString = locationString.replaceAll(')', '');
    List<String> vals = locationString.split(',');
    print("split $locationString to $vals");
    if (vals.length != 2) {
      throw Exception("Location ($locationString) should have one comma.");
    }
    latitude = double.parse(vals[0]);
    longitude = double.parse(vals[1]);
    print("transport to $latitude, $longitude");
    valid = true;
  }

  void update(LocationData data) {
    if (!auto_update) {
      return;
    }
    if (data.latitude == null || data.longitude == null) {
      return;
    }
    latitude = data.latitude!;
    longitude = data.longitude!;
    valid = true;
  }
}
