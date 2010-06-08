#! /bin/bash

cd ~/perldroid/tools

rm -rf target_core PerlDroid.zip

./make_core_modules_pkg.pl ~/perldroid/PerlDroid/jni/libperl/perl-5.10.1/install_me_here/usr/files/perl/5.10.1

mkdir -p target_droid
cd target_droid
mkdir -p arm-linux-multi/auto/PerlDroid

cd ~/perldroid/PerlDroid
~/android-ndk/ndk-build
cp -v jni/libperl/perl-5.10.1/libperl.so libs/armeabi/
cd -

mv ~/perldroid/PerlDroid/libs/armeabi/libPerlDroid_so.so arm-linux-multi/auto/PerlDroid/PerlDroid.so
find . -name "*.*" | zip ../target_core/PerlDroid.zip -@

cd ../target_core
tar cf - PerlDroid.zip | ssh root@gtmp.org /var/www/dbx.gtmp.org/android/get_pd_tar.sh
cd ..
