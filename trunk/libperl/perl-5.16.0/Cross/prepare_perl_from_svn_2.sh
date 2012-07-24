#! /bin/bash

if [[ -d %%%_XPERL_PATH_%%% || -z "$1" ]]; then
    echo "You don't want to do that. See README.android"
    cat README.android 2>/dev/null
    exit 0
fi

cd
rm -rf perl-$VERSION %%%_XPERL_PATH_%%%
tar xzf perl-$VERSION.tar.gz
mv perl-$VERSION %%%_XPERL_PATH_%%%
cd ~/perldroid/libperl/perl-$VERSION/Cross

cp -fv perl.h.android.patch Makefile.SH.android.patch make_ext.pl.android.patch installperl.android.patch Errno_pm.PL.android.patch uudmap.h.android mg_data.h.android bitcount.h.android config.sh-arm-linux-androideabi.android config.android Makefile.android miniperl.android %%%_XPERL_PATH_%%%/Cross/
cd %%%_XPERL_PATH_%%%/Cross/
make -f Makefile.android patch

echo Now do this:
echo cd %%%_XPERL_PATH_%%%/Cross/
echo make -f Makefile.android perl
