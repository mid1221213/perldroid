PERL=perl-5.10.0
LIBPERL=libperl
ME=$(shell whoami)

all: $(LIBPERL)/$(PERL)/install_me_here

$(LIBPERL)/$(PERL)/install_me_here: $(LIBPERL)/$(PERL)/Cross/Makefile.android
	cd $(LIBPERL)/$(PERL)/Cross && make -f Makefile.android perl

$(LIBPERL)/$(PERL)/Cross/Makefile.android: $(LIBPERL)/$(PERL)/Cross/README
	svn co http://perldroid.googlecode.com/svn/trunk/libperl/$(PERL)/Cross Cross
	cp Cross/* $(LIBPERL)/$(PERL)/Cross/ && rm -rf Cross
	cd $(LIBPERL)/$(PERL)/Cross && make -f Makefile.android patch

$(LIBPERL)/$(PERL)/Cross/README:
	wget http://dbx.gtmp.org/$(PERL).tar.gz
	tar -C $(LIBPERL) -zxvf $(PERL).tar.gz && rm -f $(PERL).tar.gz
	chown -R $(ME):$(ME) $(LIBPERL)/$(PERL)
	chmod 644 $(LIBPERL)/$(PERL)/Cross/*

clean:
	rm -rf $(LIBPERL)/$(PERL)
