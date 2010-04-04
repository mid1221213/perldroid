PERL=perl-5.10.0
LIBPERL=libperl
ARCH=armeabi
ME=$(shell whoami)

all: $(LIBPERL)/$(PERL)/libperl.so

$(LIBPERL)/$(PERL)/libperl.so: $(LIBPERL)/$(PERL)/Cross/Makefile.android
	cd $(LIBPERL)/$(PERL)/Cross && make -f Makefile.android perl

$(LIBPERL)/$(PERL)/Cross/Makefile.android: $(LIBPERL)/$(PERL)/Cross/README
	cp -v ../libperl/perl-5.10.0/Cross/* $(LIBPERL)/$(PERL)/Cross/
	cd $(LIBPERL)/$(PERL)/Cross && make -f Makefile.android patch

$(LIBPERL)/$(PERL)/Cross/README:
	wget -q -O - http://dbx.gtmp.org/$(PERL).tar.gz | tar -C $(LIBPERL) -zxvf -
	chown -R $(ME):$(ME) $(LIBPERL)/$(PERL)
	chmod 644 $(LIBPERL)/$(PERL)/Cross/*

clean:
	rm -rf $(LIBPERL)/$(PERL)
