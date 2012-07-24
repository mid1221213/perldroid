#! /bin/bash

VERSION=5.16.0

echo "You don't want to do that. See README.android:"
exit 0

cd
rm -rf perl-$VERSION
tar xzf perl-$VERSION.tar.gz
cd ~/perldroid/libperl/perl-$VERSION/Cross
cp -f *android* ~/perl-$VERSION/Cross/
cd ~/perl-$VERSION/Cross/
make -f Makefile.android gen_patch
cp *.android.patch ~/perldroid/libperl/perl-$VERSION/Cross
cd
rm -rf perl-$VERSION
tar xzf perl-$VERSION.tar.gz
