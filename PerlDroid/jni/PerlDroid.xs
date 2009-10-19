#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <jni.h>

int comp_sig(char sig[], char *test_sig)
{
	return 0;
}

MODULE = PerlDroid  PACKAGE = PerlDroid

SV*
XS_constructor(hp, ...)
	HV* hp;
   PREINIT:
	HV* rh;
	SV** proto;
	char *proto_str;
	SV* ret;
	int i;
	int j;
	int cur = 0;
	int fsig = 0;
	char* class;
	SV** app;
	char sig[1024];
	char* pclass;
	STRLEN len;
	SV* parami;
   CODE:
	class = HvNAME(SvSTASH(SvRV(hp)));
	app = hv_fetch(hp, "<init>", 6, 0);
	sig[cur++] = '(';

	if (items > 1) /* we have arguments */
		for (i = 1; i < items; i++) {
			parami = ST(i);
			if (SvROK(parami) && SvTYPE(SvRV(parami)) == SVt_PVMG) {
				sig[cur++] = 'L';
				pclass = HvNAME(SvSTASH(SvRV(parami)));
				for (j = strlen("PerlDroid::"); j < strlen(pclass); j++)
					if (pclass[j] == ':') {
						sig[cur++] = '/';
						cur++;
					} else if (pclass[j] == '_')
						sig[cur++] = '$';
					else
						sig[cur++] = pclass[j];
			} else {
				SvGETMAGIC(parami);
				if (SvIOKp(parami)) {
					sig[cur++] = 'I';
				} else if (SvNOKp(parami)) {
					sig[cur++] = 'D';
				} else if (SvPOKp(parami)) {
					SvPV(parami, len);
					if (len == 1)
						sig[cur++] = 'B';
					else
						sig[cur++] = 'I';
				} else {
					croak("Type not recgonized param #%d", i);
				}
			}
		}
	sig[cur++] = ')';
	sig[cur] = '\0';
	
	for (i = 0; i <= av_len((AV*)SvRV(*app)); i++) {
		proto = av_fetch((AV*)SvRV(*app), i, 0);
		proto_str = SvPV_nolen(*proto);
		if (comp_sig(sig, proto_str)) {
			fsig = 1;
		}
	}

	if (!fsig)
		croak("Signature not found");

	RETVAL = ret;
   OUTPUT:
	RETVAL
