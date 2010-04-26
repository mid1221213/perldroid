#! /bin/bash

cd ~/android-ndk/apps/perldroid/project

~/android-sdk/tools/android update project --name Snake --target 4 --path Snake/

cd Snake

ant clean && ant debug
