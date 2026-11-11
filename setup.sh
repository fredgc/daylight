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

export FLUTTER_PORT=$(find-port.py)
echo "Using port $FLUTTER_PORT"

export USE_DESKTOP=$workspace
emacs-maybe-client -n -3 README.md lib/main.dart

chrome-hot-key -n personal -w $workspace -g 1200x1000+0+50 9 "http://localhost:$FLUTTER_PORT"

chrome-hot-key -n personal -w $workspace -g 980x1010-1+30 0 \
 "https://console.firebase.google.com/project/daylight-330b4/overview"

chrome-hot-key -n personal -w $workspace -g 950x1000+100+30 t \
  "https://docs.google.com/document/d/19ESr9TL-pdcFNEsN7CH6jGBd29GVWtpy7y3GxRuSSrI/edit?tab=t.6sbpp9pn0tx8"

