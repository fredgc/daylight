#!/bin/bash -i
#
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z "$workspace" ]; then 
  export workspace=`sawfish-client -e current-workspace`
fi

export USE_DESKTOP=$workspace
emacs-maybe-client -n -2 README.md lib/main.dart

chrome-hot-key -w $workspace -g 1700x1000+0+375 9 "http://localhost:5000/#/"

chrome-hot-key -w $workspace -g +0+26 5 "https://flutter.dev/docs/get-started/codelab"
chrome-hot-key -w $workspace -g +0+26 6 "https://docs.flame-engine.org/latest/flame/flame.html"

chrome-hot-key -w $workspace -g +0+26 7 "https://launch.corp.google.com/launch/4324285"

chrome-hot-key -w $workspace -g +0+26 8 "https://g3doc.corp.google.com/company/users/mbrukman/howto/oss-releasing-speedrun.md?cl=head"

