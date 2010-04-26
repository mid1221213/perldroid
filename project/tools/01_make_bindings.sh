#! /bin/bash

cd ~/android-ndk/apps/perldroid/project/tools

rm -rf target_droid target_subclasses target_tmpl

[[ ! -f public_api.xml ]] && wget -nd -O public_api.xml "http://android.git.kernel.org/?p=platform/frameworks/base.git;a=blob_plain;f=api/current.xml;hb=donut"

./make_bindings.pl public_api.xml

cd src_tmpl

echo "Compiling PerlDroid.java"

javac -g -bootclasspath ~/android-sdk/platforms/android-4/android.jar -g -target 1.5 org/gtmp/perl/PerlDroid.java

echo "JARing PerlDroid.class"

jar cvf PerlDroid.jar org/gtmp/perl/*.class

cd ../target_subclasses

echo "Compiling..."

find . -name '*.java' >src.list
javac -bootclasspath $HOME/android-sdk/platforms/android-4/android.jar:$HOME/android-ndk/apps/perldroid/project/tools/src_tmpl/PerlDroid.jar -g -target 1.5 @src.list

echo "DEXing..."

find . -name '*.java' | xargs rm -f
rm -f src.list

~/android-sdk/platforms/android-4/tools/dx --dex --output=../subclasses.jar .

cd ..

cp -vf subclasses.jar ../PerlDroid/assets/
