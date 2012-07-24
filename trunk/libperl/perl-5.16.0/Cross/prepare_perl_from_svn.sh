#! /bin/bash

VERSION=5.16.0

if [[ ! -e ~/perl-$VERSION.tar.gz || -d ~/perl-$VERSION ]]; then
    echo "You don't want to do that. See README.android"
    cat README.android 2>/dev/null
    exit 0
fi

cd ~/perldroid/libperl/perl-$VERSION/Cross
./subst.pl config.android cpan.android Makefile.android Makefile.SH.android.patch miniperl.android MyConfig.pm prepare_perl_for_cpan.sh config.sh-arm-linux-androideabi.android prepare_perl_from_svn_2.sh

. ./prepare_perl_from_svn_2.sh doit
