#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <jni.h>
#include <string.h>

extern JNIEnv *my_jnienv;

static void perl_obj_to_java_class(char *perl_obj, char *java_class)
{
	char c;
	perl_obj += 11; /* strlen("PerlDroid::") */

	while (c = *(perl_obj++)) {
		switch(c) {
			case ':':
					*(java_class++) = '/';
					perl_obj++;
					break;
			case '_':
					*(java_class++) = '$';
					break;
			default:
					*(java_class++) = c;
					break;
		}
	}

	*java_class = '\0';
}

static int get_type(char **s, char *sb)
{
	switch(**s) {
		case 'L':
				while ((*(sb++) = *((*s)++) != ';'))
					;
				break;
		case ')':
				(*s)++;
				*(sb++) = '\0';
				return 1;
				break;
		default:
				*(sb++) = *((*s)++);
				break;
	}

	*(sb++) = '\0';
	return **s == '\0' || **s == ')';
}

static int comp_sig(char *sig, char *test_sig)
{
	char *s1, *s2;
	char sb1[128], sb2[128];
	int lo, in_param = 1;

	if (*sig != '(' || *test_sig != '(')
		croak("bad signatures: %s <=> %s", sig, test_sig);

	printf("Comparing %s and %s\n", sig, test_sig);

	for (s1 = sig + 1, s2 = test_sig + 1; *s1 && *s2;) {
		int ep1 = 0, ep2 = 0;
		ep1 = get_type(&s1, sb1);
		ep2 = get_type(&s2, sb2);

		if (strcmp(sb1, sb2)) {
			printf("%s != %s\n", sb1, sb2);
			return 0;
		}
		printf("%s == %s\n", sb1, sb2);

		if (ep1 || ep2) {
			if (ep1 && ep2) {
				if (in_param)
					in_param = 0;
				else
					return 1;
			} else
				return 0;
		}
	}

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
	char jclazz[128];
	jclass jniClass;
	jmethodID jniConstructorID;
	jobject jniObject;
   CODE:
	class = HvNAME(SvSTASH(hp));
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
				sig[cur++] = ';';
			} else {
				if (SvIOKp(parami)) {
					sig[cur++] = 'I';
				} else if (SvNOKp(parami)) {
					sig[cur++] = 'D';
				} else if (SvPOKp(parami)) {
					SvPV(parami, len);
					if (len == 1)
						sig[cur++] = 'C';
					else
						sig[cur++] = 'S';
				} else {
					croak("Type not recognized param #%d", i);
				}
			}
		}
	sig[cur++] = ')';
	sig[cur++] = 'V';
	sig[cur] = '\0';
	
	for (i = 0; i < av_len((AV*)SvRV(*app)); i++) {
		proto = av_fetch((AV*)SvRV(*app), i, 0);
		proto_str = SvPV_nolen(*proto);
		if (comp_sig(sig, proto_str)) {
			fsig = 1;
			break;
		}
	}

	if (!fsig)
		croak("Signature not found");

	perl_obj_to_java_class(class, jclazz);

	jniClass = (*my_jnienv)->FindClass(my_jnienv, jclazz);

	if(!jniClass) {
		croak("Can't find class %s", jclazz);
	}

	jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", proto_str);
	if(!jniConstructorID) {
		croak("Can't find constructor for class %s", jclazz);
	}

	jniObject = (*my_jnienv)->NewObject(my_jnienv, jniClass, jniConstructorID);
	if(!jniObject) {
		croak("Can't instantiate class %s", jclazz);
	}

	ret = newSViv(0);

	RETVAL = ret;
   OUTPUT:
	RETVAL
