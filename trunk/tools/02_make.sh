#! /bin/bash

cd ~/perldroid/PerlDroid
~/android-ndk/ndk-build
cp -v jni/libperl/perl-5.10.1/libperl.so libs/armeabi/
