#! /bin/bash

# Make libperl.so
cd ~/perldroid/PerlDroid/jni
make -f libperl.mk

# Make the rest
~/android-ndk/ndk-build
cp -v libperl/perl-5.10.1/libperl.so ../libs/armeabi/
