#! /bin/bash

VERSION=5.16.0

if [[ ! -d ~/perl-$VERSION/install_me_here || -e ~/perl-$VERSION/install_me_here/strict.pm || -d ~/.cpan ]]; then
    echo "You don't want to do that. See README.android"
    cat README.android 2>/dev/null
    exit 0
fi

mkdir -p ~/.cpan/CPAN
cp MyConfig.pm ~/.cpan/CPAN/

cd ~/perl-$VERSION/
cp ~/perldroid/libperl/perl-$VERSION/Cross/cpan.android .

cp -a install_me_here/lib/* fake_config_library/

echo now do:
echo cd ~/perl-$VERSION/
echo ./cpan.android MODULE::TO::INSTALL ...
