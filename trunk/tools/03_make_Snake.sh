#! /bin/bash

cd ~/perldroid

~/android-sdk/tools/android update project --name Snake --target 4 --path Snake/

cd Snake

ant clean && ant debug
