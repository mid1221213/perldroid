#! /bin/bash

VERSION=5.16.0

if [[ ! -d %%%_XPERL_PATH_%%%/install_me_here || -e %%%_XPERL_PATH_%%%/fake_config_library/strict.pm || -d ~/.cpan.android.%%%_DIR_PATH_%%% ]]; then
    echo "You don't want to do that. See README.android"
    cat README.android 2>/dev/null
    exit 0
fi

mkdir -p ~/.cpan.android.%%%_DIR_PATH_%%%/CPAN
cp MyConfig.pm ~/.cpan.android.%%%_DIR_PATH_%%%/CPAN/

cd %%%_XPERL_PATH_%%%
cp ~/perldroid/libperl/perl-$VERSION/Cross/cpan.android .

mv perl perl.target
ln -s miniperl perl
mv fake_config_library/Config.pm fake_config_library/Config_heavy.pl install_me_here/lib/
rmdir fake_config_library && ln -s install_me_here/lib/ fake_config_library

echo Now do:
echo cd %%%_XPERL_PATH_%%%
echo PATH=\$PATH:%%%_XPERL_PATH_%%%
echo ./cpan.android MODULE::TO::INSTALL ...
