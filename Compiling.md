Follow these steps to build the project as it is today (2010-04-11). I made the checkout to get [r179](https://code.google.com/p/perldroid/source/detail?r=179) on purpose, because following commits may change the build sequence.

This works on an Ubuntu 9.10 server just installed (tested on a fresh install in a virtual machine). Please follow these steps carefully, especially for the 'cd' commands because the working directory is important.

Important note: The design of the PerlDroid application is that the .apk does not contain core modules. These are loaded from my own server (http://dbx.gtmp.org/android/perl-core-modules-5.10.0/...). For the moment I don't explain how to build your own repository and the URL is hard-coded in the .java source.

  1. Install required packages
```
sudo apt-get --no-install-recommends install build-essential unzip subversion sun-java6-jdk ant
```
  1. Get Android SDK (with version 1.6 (android-4) tools) and NDK
```
wget http://dl.google.com/android/android-sdk_r05-linux_86.tgz
tar zxvf android-sdk_r05-linux_86.tgz
ln -s android-sdk-linux_86 android-sdk

wget https://dl-ssl.google.com/android/repository/android-1.6_r02-linux.zip
cd android-sdk/platforms
unzip ~/android-1.6_r02-linux.zip
mv android-1.6_r02-linux android-4

cd
wget http://dl.google.com/android/ndk/android-ndk-r3-linux-x86.zip
unzip android-ndk-r3-linux-x86.zip
ln -s android-ndk-r3 android-ndk
cd android-ndk
build/host-setup.sh
```
  1. Now get the PerlDroid source
```
cd ~/android-ndk/apps
svn checkout http://perldroid.googlecode.com/svn/trunk/@179 perldroid
```
  1. Next step is to get perl source (5.10.0, on my server), compile libperl.so and libPerlDroid.so (and to remove libPerlDroid\_so.so which is only needed to build PerlDroid.so). This step will take a lot of time but should end nicely with no error.
```
cd ..
make APP=perldroid
rm apps/perldroid/project/libs/armeabi/libPerlDroid_so.so 
```
  1. Then make Java projects compilable by the SDK
```
cd apps/perldroid/project/
~/android-sdk/tools/android update project --name PerlDroid --target android-4 --path PerlDroid
~/android-sdk/tools/android update project --name PerlDialog --target android-4 --path PerlDialog
```
  1. Compile them
```
cd PerlDroid
ant debug
cd ..

cd PerlDialog
ant debug
cd ..
```
  1. Last step is to install them on the phone or emulator. This will work only if an emulator is started or a phone connected.
```
~/android-sdk/tools/adb install PerlDroid/bin/PerlDroid-debug.apk
~/android-sdk/tools/adb install PerlDialog/bin/PerlDialog-debug.apk
```

Now you can start on the emulator / phone the PerlDroid application. This one will download core modules precompiled from my server and install them. When finished, tap the screen and press the Home Button. This step is required only once. Now, the PerlDroid application is useless but don't delete it, it contains libperl.so and libPerlDroid.so needed by Perl applications like PerlDialog.

Finally, start the PerlDialog application. It should display a dialog saying something in French ;-)

The source of the PerlDialog Perl program is:

```
use strict;
use R;

$| = 1;
use PerlDroid;
use PerlDroid::android::content;
use PerlDroid::android::app;
use PerlDroid::android::widget;

use vars qw/$this/;

my $pm = PerlDroid::XS_proxy($DialogInterface_OnClickListener, "PerlDialog::DialogInterface");

my $adb = $AlertDialog_Builder->new($this);
$adb->setMessage('Salut ma poule !');
$adb->setPositiveButton('Ok', $pm);
$adb->setNegativeButton('Dégage', $pm);
$adb->create;
$adb->show;

print "Ok\n";
warn 'classthis = ' . $this->getClass->getName;
printf("R.layout.main=0x%x\n", $R{layout}{main});
$this->findViewById($R{id}{TV})->cast($TextView)->setText("Mid was here! :-)");

package PerlDialog::DialogInterface;

sub onClick {
    my ($arg1, $arg2) = @_;
    print "arg1=$arg1, arg2=$arg2\n";
    if ($arg2 == - 1) {
        warn 'class1 = ' . $arg1->getClass->getName;
        $arg1->cancel;
    } else {
        warn 'classthis = ' . $main::this->getClass->getName;
        $main::this->finish;
    }
}
```

Note: starting the PerlDialog application again may fail because for the moment I don't manage correctly the lifetime cycle of Android application. This is normal.

Note2: Thanks to Benoît Rouits for that build sequence.