#! /bin/bash

echo -n "Are you sure you want to proceed (Return for OK, ^C for NOK)?"; read ok

rm -rf target_core PerlDroid.zip

./make_core_modules_pkg.pl ~/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0

cd target_droid
mkdir -p arm-linux-multi/auto/PerlDroid
cd ../../PerlDroid/jni/
make
cd -
cp ../../PerlDroid/jni/PerlDroid.so arm-linux-multi/auto/PerlDroid/
find . -name "*.*" | zip ../target_core/PerlDroid.zip -@

cd ../target_core
tar cf - * | ssh root@gtmp.org /var/www/dbx.gtmp.org/android/get_core_tar.sh
cd ..
