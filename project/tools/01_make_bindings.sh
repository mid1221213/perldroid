#! /bin/bash

rm -rf target_droid
wget -nd -O public_api.xml "http://android.git.kernel.org/?p=platform/frameworks/base.git;a=blob_plain;f=api/current.xml;hb=cupcake"

./make_bindings.pl public_api.xml
