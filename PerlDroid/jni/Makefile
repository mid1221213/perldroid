all: hello_perl libPerlDroid.so

hello_perl: Makefile hello_perl.c div.o
	agcc -o hello_perl -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I${HOME}/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0/arm-linux-multi/CORE/ hello_perl.c div.o -L. -ldl

libPerlDroid.so: libPerlDroid.o div.o Makefile
	agcc -shared -o libPerlDroid.so libPerlDroid.o ${HOME}/mydroid/out/target/product/generic/obj/SHARED_LIBRARIES/libnativehelper_intermediates/JNIHelp.o div.o -L. -ldl -lcutils
	cp -f libPerlDroid.so ../libs/armeabi

libPerlDroid.o:  libPerlDroid.c Makefile
	agcc -c libPerlDroid.c  -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I${HOME}/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0/arm-linux-multi/CORE/ -I${HOME}/mydroid/dalvik/libnativehelper/include/nativehelper/

div.o: div.c Makefile
	agcc -c div.c

clean:
	rm -f div.o hello_perl libPerlDroid.o libPerlDroid.so
