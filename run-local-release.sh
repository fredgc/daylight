#!/bin/bash

set -ex

# This builds the server for release, and runs locally so that
# there is not a lot of debug overhead on a slow network connection.

if [ `hostname -s` == "raven" ]; then
    export FLUTTER_PORT=5525
else 
    export FLUTTER_PORT=5010
fi
echo "Using port $FLUTTER_PORT"

make docs web/favicon.ico

flutter build web --release

grep version: pubspec.yaml

python3 -m http.server $FLUTTER_PORT --directory build/web
