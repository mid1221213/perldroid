all: hello_perl libPerlDroid.so PerlDroid.so

hello_perl: hello_perl.c Makefile
	agcc -o hello_perl -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I${HOME}/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0/arm-linux-multi/CORE/ hello_perl.c -L. -ldl

libPerlDroid.so: libPerlDroid.o libperl.so Makefile
	agcc -shared -o libPerlDroid.so libPerlDroid.o ${HOME}/mydroid/out/target/product/generic/obj/SHARED_LIBRARIES/libnativehelper_intermediates/JNIHelp.o -L. -ldl -lcutils
	cp -f libPerlDroid.so ../libs/armeabi
	cp -f libperl.so ../libs/armeabi

libPerlDroid.o:  libPerlDroid.c Makefile
	agcc -c libPerlDroid.c  -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I${HOME}/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0/arm-linux-multi/CORE/ -I${HOME}/mydroid/dalvik/libnativehelper/include/nativehelper/

PerlDroid.so: PerlDroid.o Makefile libperl.so
	agcc -shared -o PerlDroid.so PerlDroid.o ${HOME}/mydroid/out/target/product/generic/obj/SHARED_LIBRARIES/libnativehelper_intermediates/JNIHelp.o -L. -ldl -lcutils -lperl

PerlDroid.o: PerlDroid.c Makefile
	agcc -c PerlDroid.c  -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I${HOME}/perl-5.10.0/install_me_here/usr/lib/perl/5.10.0/arm-linux-multi/CORE/ -I${HOME}/mydroid/dalvik/libnativehelper/include/nativehelper/

PerlDroid.c: PerlDroid.xs Makefile
	xsubpp -prototypes -output PerlDroid.c PerlDroid.xs

clean:
	rm -f hello_perl libPerlDroid.o libPerlDroid.so PerlDroid.so PerlDroid.so
