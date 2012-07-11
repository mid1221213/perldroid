#! /bin/bash

VERSION=5.16.0

echo "You don't want to do that. See README.android"
cat README.android 2>/dev/null
exit 0

cd
rm -rf perl-$VERSION
tar xzf perl-$VERSION.tar.gz
cd ~/perldroid/libperl/perl-$VERSION/Cross
cp -fv perl.h.android.patch Makefile.SH.android.patch make_ext.pl.android.patch installperl.android.patch Errno_pm.PL.android.patch uudmap.h.android mg_data.h.android bitcount.h.android config.sh-arm-linux.android config.android Makefile.android miniperl.android ~/perl-$VERSION/Cross/
cd ~/perl-$VERSION/Cross/
make -f Makefile.android patch

echo Now do this:
echo cd ~/perl-$VERSION/Cross/
echo make -f Makefile.android perl