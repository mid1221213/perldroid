# How to compile perl-5.16.0 for Android #

Follow these steps to build the project as it is today (2012-07-24). I made the checkout to get [r298](https://code.google.com/p/perldroid/source/detail?r=298) on purpose, because following commits may change the build sequence.

This works on an Ubuntu 12.04 server 64 bit just installed with only openssh-server (tested on a fresh install in a virtual machine). Please follow these steps carefully, especially for the `cd` commands because the working directory is important. This procedure takes about 40 minutes to complete on my machine.

**New:** No more need for a virtual machine, the procedure now installs host perl in $HOME.

**New:** The procedure now names the cross compiled perl directory according to the arch and Android target version, in this case `perl-arm-5.16.0-14`.

  1. Be sure host is up to date
```
sudo apt-get update && sudo apt-get dist-upgrade
# reboot if necessary
```
  1. Install required packages (include `ia32-libs` only if you use a 64 bit OS)
```
sudo apt-get --no-install-recommends install build-essential subversion ia32-libs
```
  1. To cross compile perl, the host should provide the same version of the executable than the one being cross compiled. As Ubuntu 12.04 provides perl 5.14.2, we need to install perl 5.16.0 from source on the host.
```
wget -nd http://www.cpan.org/src/5.0/perl-5.16.0.tar.gz
tar xzf perl-5.16.0.tar.gz
cd perl-5.16.0/
./Configure -des -Dprefix=~/hostperl-5.16.0
make
make install
cd
mv perl-5.16.0 perl-5.16.0.host
PATH=~/hostperl-5.16.0/bin:$PATH
```
  1. Get the Android NDK (SDK not necessary)
```
wget -nd http://dl.google.com/android/ndk/android-ndk-r8b-linux-x86.tar.bz2
tar xjf android-ndk-r8b-linux-x86.tar.bz2
ln -s android-ndk-r8b android-ndk
export NDK=~/android-ndk
```
  1. Install now the standalone toolchain
```
$NDK/build/tools/make-standalone-toolchain.sh --platform=android-14 --install-dir=$HOME/android_toolchain
PATH=~/android_toolchain/bin:$PATH
```
  1. Now get the PerlDroid source
```
svn checkout http://perldroid.googlecode.com/svn/trunk/@298 perldroid
cd ~/perldroid/libperl/perl-5.16.0/Cross
```
  1. There is a script to automate the patching of the perl source tree. It will expect a perl source as downloaded above and will untar it at the same place as before. Launch it
```
./prepare_perl_from_svn.sh
```
  1. Copy / paste the last 2 output lines:
```
cd ~/perl-arm-5.16.0-14/Cross/
make -f Makefile.android perl
```
The last step above will start the compilation. This will take some time and display a lot of messages. On my system it takes approximatively 5 minutes. The 3 last output lines should be:
```
...
cd /home/mid/perl-arm-5.16.0-14/Cross/.. ; sh -x Cross/warp
+ find lib -name install_me_here
+ find lib -name install_me_here
```
with the username being yours. There should be no error, of course.

The compiled distribution can now be found in the directory `~/perl-arm-5.16.0-14/install_me_here/` and the `libperl.so` is in `~/perl-arm-5.16.0-14/install_me_here/lib/linux-androideabi-thread-multi/CORE/libperl.so`.

More information is coming to talk about APK integration with the [perl-android-apk](http://code.google.com/p/perl-android-apk/) project, how I generated the file `config.sh-arm-linux.androideabi` and how to customize it.

Have a nice day! ;-)

---

© _Mid'_, 2012 ;-)