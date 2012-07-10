#! /bin/bash

usage()
{
    echo 'Usage: make_zips.sh <PERL_CORE_ZIPS install_dir> "<PERL_CORE modules>" <CPAN install_dir> "<CPAN modules>"'
    exit
}

CUR_DIR=`pwd`

SCRIPT_PATH=`dirname $0`
[[ ${SCRIPT_PATH#/} == $SCRIPT_PATH ]] && SCRIPT_PATH=$CUR_DIR/$SCRIPT_PATH

ANDROID_PM=$SCRIPT_PATH/Android.pm

PM_NAME=perl_516_sdcard
SO_NAME=perl_516

CORE_SRC_PATH=$1
[[ -d $CORE_SRC_PATH ]] || usage
[[ ${CORE_SRC_PATH#/} == $CORE_SRC_PATH ]] && CORE_SRC_PATH=$CUR_DIR/$CORE_SRC_PATH
[[ ${CORE_SRC_PATH%/} != $CORE_SRC_PATH ]] && CORE_SRC_PATH=${CORE_SRC_PATH%/}

CORE_EXTRA=$2

CPAN_SRC_PATH=$3
[[ -d $CPAN_SRC_PATH ]] || usage
[[ ${CPAN_SRC_PATH#/} == $CPAN_SRC_PATH ]] && CPAN_SRC_PATH=$CUR_DIR/$CPAN_SRC_PATH
[[ ${CPAN_SRC_PATH%/} != $CPAN_SRC_PATH ]] && CPAN_SRC_PATH=${CPAN_SRC_PATH%/}

CPAN_EXTRA=$4

CORE_MIN="__PERL__ attributes AutoLoader autouse B base bigint bignum bigrat blib bytes Carp Carp::Heavy charnames Config constant Data::Dumper diagnostics DynaLoader encoding Exporter Exporter::Heavy feature fields Getopt::Long if integer less lib mro open ops overload overloading re sigtrap sort strict subs threads Time::HiRes UNIVERSAL utf8 vars version warnings warnings::register XSLoader IO IO::Socket IO::Socket::INET IO::Socket::UNIX IO::Handle Symbol SelectSaver Socket Errno JSON::PP HTTP::Tiny"
CPAN_MIN="JSON JSON::XS"

tmpdir=`mktemp -d`

PM_DIR=$tmpdir/$PM_NAME/perl/site_perl
SO_DIR=$tmpdir/$SO_NAME/perl

mkdir -p $PM_DIR $SO_DIR

for type in pm so; do
    if [[ $type == "pm" ]]; then
	src_dir=$PM_DIR
	zip_dir=$tmpdir/$PM_NAME
	name=$PM_NAME
    else
	src_dir=$SO_DIR
	zip_dir=$tmpdir/$SO_NAME
	name=$SO_NAME
    fi

    for mod in $CORE_MIN $CORE_EXTRA; do
	zip=$CORE_SRC_PATH/target_core_$type/$mod.zip
	if [[ -e $zip ]]; then
	    cd $src_dir
	    unzip -qq $zip
	    cd - >/dev/null 2>&1
	else
	    [[ $type == "pm" && $mod != "__PERL__" ]] && echo "$mod.pm not found!"
	fi
    done

    for mod in $CPAN_MIN $CPAN_EXTRA; do
	for rel_dir in "" arm-linux-androideabi arm-linux-androideabi/auto site_perl/5.16.0 site_perl/5.16.0/arm-linux-androideabi site_perl/5.16.0/arm-linux-androideabi/auto; do
	    dir=$CPAN_SRC_PATH/perl5/$rel_dir
	    mod_dir=`echo $mod | sed -e 's/::/\//g'`
	    packlist=$dir/$mod_dir/.packlist
	    [[ -e $packlist ]] && break
	done

	if [[ -e $packlist ]]; then
	    if [[ $type == "pm" ]]; then
		filelist=`sed "s,$CPAN_SRC_PATH/perl5/,,g" < $packlist | egrep -v '\.(so|bs)$' | fgrep -v /bin/`
	    else
		filelist=`sed "s,$CPAN_SRC_PATH/perl5/,,g" < $packlist | egrep '\.(so|bs)$'`
	    fi

	    for file in $filelist; do
		cd $src_dir
		dst_rel_dir=`dirname $file | sed -E "s,site_perl/,,"`
		mkdir -p $dst_rel_dir
		cp $CPAN_SRC_PATH/perl5/$file $dst_rel_dir
		cd - >/dev/null 2>&1
	    done
	else
	    [[ $type == "pm" ]] && echo "packlist for $mod not found!"
	fi
    done

    cd $zip_dir
    [[ $type == "pm" ]] && cp $ANDROID_PM $src_dir
    zip -rqq $CUR_DIR/$name.zip *
    cd - >/dev/null 2>&1
done

rm -rf $tmpdir

echo Done.
