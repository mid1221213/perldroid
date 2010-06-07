#! /bin/bash

cd ~/perldroid/project/tools

rm -rf target_core PerlDroid.zip

./make_core_modules_pkg.pl ~/perldroid/project/jni/libperl/perl-5.10.1/install_me_here/usr/files/5.10.1

mkdir -p target_droid
cd target_droid
mkdir -p arm-linux-multi/auto/PerlDroid
cd ~/perldroid
~/android-ndk/ndk-build
cd -
mv ~/perldroid/project/libs/armeabi/libPerlDroid_so.so arm-linux-multi/auto/PerlDroid/PerlDroid.so
find . -name "*.*" | zip ../target_core/PerlDroid.zip -@

cd ../target_core
tar cf - * | ssh root@gtmp.org /var/www/dbx.gtmp.org/android/get_core_tar.sh
cd ..
