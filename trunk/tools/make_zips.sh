#! /bin/bash

usage()
{
    echo "Usage: make_zips.sh <source_dir>"
    exit
}

SRC_PATH=$1
[[ -d $SRC_PATH ]] || usage
SRC_PATH=`pwd`/`basename $SRC_PATH`

CORE_MIN="attributes AutoLoader autouse B base bigint bignum bigrat blib bytes Carp Carp::Heavy charnames Config constant Data::Dumper diagnostics DynaLoader encoding Exporter Exporter::Heavy feature fields Getopt::Long if integer less lib mro open ops overload overloading re sigtrap sort strict subs threads Time::HiRes UNIVERSAL utf8 vars version warnings warnings::register XSLoader IO IO::Socket IO::Socket::INET IO::Socket::UNIX IO::Handle Symbol SelectSaver Socket Errno JSON JSON::PP HTTP::Tiny"

tmpdir=`mktemp -d`

for type in pm so; do
    mkdir $tmpdir/$type
    cd $tmpdir/$type

    for mod in $CORE_MIN; do
	zip=$SRC_PATH/target_core_$type/$mod.zip
	if [[ -f $zip ]]; then
	    echo $mod.$type
	    unzip -qq $zip
	fi
    done

    zip -r $SRC_PATH/target_$type.zip *
done

rm -rf $tmpdir
