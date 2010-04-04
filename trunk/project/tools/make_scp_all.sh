#! /bin/bash

cd ~/android-ndk/apps/perldroid/project/tools

rm -rf target_core PerlDroid.zip

./make_core_modules_pkg.pl ~/android-ndk/apps/perldroid/project/jni/libperl/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0

mkdir target_droid
cd target_droid
mkdir -p arm-linux-multi/auto/PerlDroid
cd ../../PerlDroid/jni/
make
cd -
mv ~/android-ndk/apps/perldroid/project/libs/armeabi/libPerlDroid_so.so arm-linux-multi/auto/PerlDroid/PerlDroid.so
find . -name "*.*" | zip ../target_core/PerlDroid.zip -@

cd ../target_core
tar cf - * | ssh root@gtmp.org /var/www/dbx.gtmp.org/android/get_core_tar.sh
cd ..
