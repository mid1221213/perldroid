#! /bin/bash

VERSION=5.10.1

# Clean up
cd ~/perldroid/tools
rm -rf target_core PerlDroid.zip

# Make core modules
./make_core_modules_pkg.pl ../PerlDroid/jni/libperl/perl-$VERSION/install_me_here/usr/files/$VERSION

# Make libperl.so & the rest
./02_make.sh

# Copy XS module and zip it
mkdir -p target_droid/arm-linux-multi/auto/PerlDroid target_core
cd target_droid
mv ~/perldroid/PerlDroid/libs/armeabi/libPerlDroid_so.so arm-linux-multi/auto/PerlDroid/PerlDroid.so
find . -name "*.*" | zip ../target_core/PerlDroid.zip -@

# Upload to server
cd ../target_core
tar cf - * | ssh www-data@gtmp.org /var/www/dbx.gtmp.org/android/get_core_tar.sh
