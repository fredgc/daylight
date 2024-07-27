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

import 'package:location/location.dart';

class LocalLocation {
  double latitude = 0.0;
  double longitude = 0.0;

  Location location = new Location();
  StreamSubscription? listener;
  bool valid = false;
  bool auto_update = true;

  // Initialize the location service.
  void init() async {
    // print("Location init.");
    await refresh();
    // print("End of init. location valid = $valid");
  }

  void dispose() async {
    // print("XXX Disposing of listener $listener");
    await listener?.cancel();
    // print("Finished disposing of listener $listener");
  }

  // Refresh the location from the service, if possible.
  // Also, turn on auto update.
  Future<void> refresh() async {
    print("Refresh location.");
    auto_update = true;

    await listener?.cancel();
    location = new Location();
    listener = location.onLocationChanged.listen((LocationData data) {
        print("Location updated via listener! data = $data");
        update(data);
    });

    print("Checking service.");
    bool service_enabled = await location.serviceEnabled();
    if (!service_enabled) {
      print("Service is not enabled. Requesting it.");
      service_enabled = await location.requestService();
      if (!service_enabled) {
        print("ERROR: service is still not enabled.");
        return;
      }
    }
    print("Checking permission.");
    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      print("Permission denied. Requesting permission.");
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) {
        print("Permission still denied! Giving up!");
        return;
      }
    }
    print("Getting location.");
    LocationData data = await location.getLocation();
    valid = true;
    print("Got location. updating, valid = $valid.");
    update(data);
    print("Finished update. valid = $valid.");
  }

  // Convert the location to a string, for display or debug.
  String toString() {
    if (valid) {
      return "(${latitude.toStringAsFixed(2)}, "
      +"${longitude.toStringAsFixed(2)})";
    }
    return "<unknown location>";
  }

  // Parse the string into a location, for debugging.
  // Also, turn off auto update.
  // Might throw a Parse exception.
  void transport(String location_string) {
    auto_update = false;
    // Trim off extra characters (whitespace and parentheses), and
    // split by the comma.
    location_string = location_string.replaceAll(' ', '');
    location_string = location_string.replaceAll('(', '');
    location_string = location_string.replaceAll(')', '');
    List<String> vals = location_string.split(',');
    print("split $location_string to $vals");
    if (vals.length != 2) {
      throw Exception("Location ($location_string) should have one comma.");
    }
    latitude = double.parse(vals[0]);
    longitude = double.parse(vals[1]);
    print("transport to $latitude, $longitude");
    valid = true;
  }

  void update(LocationData data) {
    print("update location data = $data");
    if (!auto_update) {
      print("Auto-update disabled while debugging.");
      return;
    }
    if (data.latitude == null || data.longitude == null) {
      print("Data had null values.");
      return;
    }
    latitude = data.latitude!;
    longitude = data.longitude!;
    print("Updated location ${toString()}. location valid = $valid");
  }

}
