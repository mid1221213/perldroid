# Introduction #

This .plan lists the things members are working on.

# Page closed #

This page is now closed. Use [Issue Tracker](http://code.google.com/p/perldroid/issues/list) to register new tasks.

# Details #

## Ben ##
  * make a shared sandbox: see the `sandbox` svn branch. **(done)**
  * find the _oldest_ android revision that compile flawlessly. **Update:** Given the few available branches on http://android.git.kernel.org/ the _oldest_ android that compile is more recent than the android which is on the HTC G1, so it is impossible to build a bionic libc that, in terms of C API, matches exactly the one on the HTC phone. :-( **(won't do)**
  * make a Cross/ that allow perl-5.10.0 to compile on that old android revision. **Update:** currently, [libperl.so](LibPerl.md) only compiles on a too recent bionic libc. workarounds must be done to allow then to use it on the phone. :-( **(won't do)**
  * put a Cross/ that work with the latest android in trunk **(done)**
  * applause Mid's 5+4=9 first PerlDroid application that **actually work on the phone**!

## Mid ##
  * Proofs of concepts / tests on real G1 phone
  * Java code to download and install core-modules in /sdcard **Update:** NOT POSSIBLE to mmap from /sdcard :-(
  * Core modules will be optional. Make a perl program to package them **Update:** Done
  * Java code to download and install core-modules in /data/data/org.gtmp.perl/lib **Update:** Done in /data/data/..../files instead due to Android limitation on creating files and directories


