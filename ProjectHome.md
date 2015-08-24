# perldroid #

The « PerlDroid » project aims to port the language Perl on Android.

For this, a lot of work has been done to cross compile perl 5.16.0. The project also focuses on three more goals:

  * Setting up a repository for perl, CORE modules and CPAN modules. More on this later, work in progress.
  * Making an Android application that will contain the perl interpreter and all necessary modules. Each other application willing to use perl will be able to ask for it to download its required (`use`'d) modules and all management of perl will be done in this application. This was a goal of the original PerlDroid project. More on this later, too ;-)
  * Working with the [perl-android-apk](http://code.google.com/p/perl-android-apk/) project which aims to embed an interpreter in an application APK. PerlDroid will provide it with a cross compiled perl interpreter and will host the repository of CORE and CPAN modules.

There will then be 2 ways of using perl for Android, depending on your needs.


---


## NEWS ##

**2014-08-13:** perl 5.20 is available and can be cross compiled for Android without hacks. So work on this project can continue when I'll have more time. Stay tuned!

**2013-09-04:** No work has been done anymore on this project due to the existence of a TPJ grant to improve cross compilation of perl. At the time of this writing it is still not yet included in the perl distribution. Work will continue as soon as this work will be included in perl distribution.

**2012-07-24:** You can now install more than one cross compiled perl in your $HOME, the name of the directory now matches the arch, perl version and Android version. See [here](Compiling5160.md).

**2012-07-22:** No more need for a virtual machine, you can install the host perl in your home. See [here](Compiling5160.md).

**2012-07-10:** A procedure explaining how to make package for [perl-android-apk](http://code.google.com/p/perl-android-apk/) is available [here](GenerateZips.md).

**2012-07-09:** Now with a method to cross compile EUMM CPAN modules. A [wiki page](Cpan5160.md) explains how to do it. **Update:** It works for MB modules too.

**2012-06-20:** New experiments have been done and perl-5.16.0 was successfully cross compiled on NDK toolchain android-14, along with **all** core modules. However I haven't tested all of them (yet) ;-)

There is a [wiki page](Compiling5160.md) showing the procedure.


---


Due to difficulties to implement the [bindings](OldHome.md), I don't plan to work on them anymore. Instead, I'm working with the [perl-android-apk](http://code.google.com/p/perl-android-apk/) project to provide a recent and full perl interpreter with a procedure to build almost any CPAN module.