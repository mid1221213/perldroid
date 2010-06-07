#! /bin/bash

cd ~/perldroid

~/android-sdk/tools/android update project --name PerlDroid --target 4 --path PerlDroid/

cd PerlDroid

ant clean && ant debug
