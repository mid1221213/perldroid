#! /bin/bash

# Make libperl.so
cd ~/perldroid/PerlDroid/jni
make -f libperl.mk

# Make the rest
~/android-ndk/ndk-build

# Copy libperl.so to libs
cp -v libperl/perl-5.10.1/libperl.so ../libs/armeabi/

# Remove libPerlDroid_so.so (not needed for PerlDroid.apk)
rm -f ../libs/armeabi/libPerlDroid_so.so
