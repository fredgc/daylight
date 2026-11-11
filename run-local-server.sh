#!/bin/bash

if [ `hostname -s` == "raven" ]; then
    export FLUTTER_PORT=5525
else 
    export FLUTTER_PORT=5010
fi
echo "Using port $FLUTTER_PORT"

make docs web/favicon.ico

flutter run -d chrome --web-port $FLUTTER_PORT
