# Introduction #

To build libperl.so is the first step before anything about using Perl on Android.


# Details #

We use the android prebuilt toolchain and the agcc gcc wrapper to build libperl upon the [bionic](OnBionic.md) libc. once libperl is built, it cannot be used as is on the HTC G1 phone because of missing symbols in that older version. So, to build a binary that uses libperl on android, we must add some object files from the latest bionic source to link with:
  * div.c

# What after ? #

Once libperl.so is built, we must build a wrapper that is usable by the android platform.
You may know that android does not support anything but a Java application... So, libperl's interface must be bound into a [Jni](Jni.md) wrapper: LibPerlDroid.

# UPDATE 2010-04-21 #

This page is outdated.