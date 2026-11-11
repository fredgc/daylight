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
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<void> reloadAndFlushCache() async {
  try {
    debugPrint("Flushing service workers, caches, and reloading page.");
    final nav = web.window.navigator;
    final serviceWorker = nav.serviceWorker;
    final registrations = await serviceWorker.getRegistrations().toDart;
    final regList = registrations.toDart;
    for (final reg in regList) {
      reg.unregister();
    }
    final cacheStorage = web.window.caches;
    final keys = await cacheStorage.keys().toDart;
    final keyList = keys.toDart;
    for (final key in keyList) {
      cacheStorage.delete(key.toDart);
    }
  } catch (e) {
    debugPrint("Error clearing web cache: $e");
  }
  web.window.location.reload();
}

Future<void> checkServerVersionAndReload(String clientVersion) async {
  try {
    final uri = "version.json?nocache=${DateTime.now().millisecondsSinceEpoch}";
    final response = await web.window.fetch(uri.toJS).toDart;
    if (response.status == 200) {
      final text = (await response.text().toDart).toDart;
      final data = jsonDecode(text) as Map<String, dynamic>;
      final serverVer = data['version'] as String?;
      final serverBuild = data['build_number'] as String?;
      final serverVersion =
          (serverBuild != null && serverBuild.isNotEmpty && serverVer != null)
              ? '$serverVer+$serverBuild'
              : serverVer;
      if (serverVersion != null &&
          serverVersion.isNotEmpty &&
          serverVersion != clientVersion) {
        debugPrint(
          "Server version ($serverVersion) differs from client ($clientVersion). Auto reloading...",
        );
        await reloadAndFlushCache();
      }
    }
  } catch (e) {
    debugPrint("Error checking server version: $e");
  }
}
