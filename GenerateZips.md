**This page is a bit outdated. It will be updated when some work on this procedure will be done.**

# How to generate .ZIP's #

Follow these steps to generate .ZIP's files containing all necessary files to use with [perl-android-apk](http://code.google.com/p/perl-android-apk/).

This procedure **needs an already cross compiled perl**. Please refer to [Compiling5160](Compiling5160.md) to know how to do it. It also needs a prepared environment for cross compiling CPAN modules, see [Cpan5160](Cpan5160.md).

  1. Change directory to cross compiled perl and execute the provided `cpan.android` script to install JSON and JSON::XS, which are **required**
```
cd ~/perl-5.16.0
./cpan.android JSON
# answer 'Y' to question about JSON::XS
```
  1. Using the same script, cross compile any CPAN module you wish
```
./cpan.android My::Module My::Other::Module ...
```
  1. Go to the tools directory and build the .ZIP files containing all the core modules. The script takes one argument: the place where the core modules from the "installed" perl distribution are located. This tool will create two directories: `target_core_pm` and `target_core_so`, which will contain one or two .ZIP file for each core module. In `target_core_pm` there will be a .ZIP containing the text part of the module. If the module is an XS module, there will be in `target_core_so` another .ZIP containing only the shared libraries (possibly along with a .bs file). .ZIP's files are named accordingly to the module names, e.g. `Tie::File.zip`
```
cd ~/perldroid/tools
./make_core_modules_pkg.pl ~/perl-5.16.0/install_me_here/lib/
```
  1. Now, generate the `perl_516.zip` and `perl_516_sdcard.zip` using `make_zips.sh`. The following example adds in the minimal .ZIP's files 2 core modules (`Tie::File` and `Time::Local`) and 2 fictitious CPAN modules (`MY::Module` `My::Other::Module`)
```
./make_zips.sh . "Tie::File Time::Local" ~/cpan_android/lib "MY::Module My::Other::Module"
```

The resulting .ZIP's files are then created in the current directory.

Have fun!

---

© _Mid'_, 2012 ;-)