#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <jni.h>
#include <string.h>

extern JNIEnv *my_jnienv;

char *nat2cls[] = {
	"Zjava/lang/Boolean",
	"Bjava/lang/Byte",
	"Cjava/lang/Character",
	"Sjava/lang/Short",
	"Ijava/lang/Int",
	"Jjava/lang/Long",
	"Fjava/lang/Float",
	"Djava/lang/Double",
	"sjava/lang/String"
};

typedef struct {
	char *class;
	SV *sigs;
	jobject jobj;
} PerlDroid;

static int perl_obj_to_java_class(char *perl_obj, char *java_class)
{
	char c;
	char *java_class_orig = java_class;

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

	return java_class - java_class_orig;
}

static int get_type(char **s, char *sb)
{
	switch(**s) {
		case 'L':
				while ((*(sb++) = *((*s)++)) != ';')
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

static int comp_types(char *t1, char *t2)
{
	int lo, ok;
	char *f1 = NULL, *f2 = NULL, c;
	jclass jc1, jc2;

	if (!*t1 || *t1 == 'V' || !*t2 || *t2 == 'V')
		if ((!*t1 || *t1 == 'V') && (!*t2 || *t2 == 'V'))
			return 1;
		else
			return 0;

	if (*t1 == 'L') {
		f1 = t1 + 1;
		f1[strlen(f1) - 1] = '\0';
	}
	if (*t2 == 'L') {
		f2 = t2 + 1;
		f2[strlen(f2) - 1] = '\0';
	}

	for (lo = 0; lo < sizeof(nat2cls) && (!f1 || !f2); lo++) {
		c = nat2cls[lo][0];
		if (*t1 == c)
			f1 = nat2cls[lo] + 1;
		if (*t2 == c)
			f2 = nat2cls[lo] + 1;
	}

	jc1 = (*my_jnienv)->FindClass(my_jnienv, f1);
	jc2 = (*my_jnienv)->FindClass(my_jnienv, f2);

	ok = (*my_jnienv)->IsAssignableFrom(my_jnienv, jc1, jc2);

	if (!ok && *t1 == 'C') {
		jc1 = (*my_jnienv)->FindClass(my_jnienv, "java/lang/String");
		ok = (*my_jnienv)->IsAssignableFrom(my_jnienv, jc1, jc2);
	}

	return ok;
}

static int comp_sig(char *sig, char *test_sig)
{
	char *s1, *s2;
	char sb1[128], sb2[128];
	int lo, in_param = 1;

	if (*sig != '(' || *test_sig != '(')
		croak("bad signatures: %s <=> %s", sig, test_sig);

	for (s1 = sig + 1, s2 = test_sig + 1; *s1 && *s2;) {
		int ep1 = 0, ep2 = 0;
		ep1 = get_type(&s1, sb1);
		ep2 = get_type(&s2, sb2);

		warn("comp_types %s, %s", sb1, sb2);
		if (!comp_types(sb1, sb2))
			return 0;

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

PerlDroid *
XS_constructor(hp, ...)
	HV* hp;
   PREINIT:
	SV** proto;
	char *proto_str;
	int i;
	int cur = 0;
	int fsig = 0;
	char* CLASS;
	SV** app;
	char sig[1024];
	char* pclass;
	STRLEN len;
	SV* parami;
	char jclazz[128];
	jclass jniClass;
	jmethodID jniConstructorID;
	jobject jniObject;
	jvalue params[128];
	PerlDroid *ret;
	IV tmp_param;
	PerlDroid *pd_param;
   CODE:
	CLASS = HvNAME(SvSTASH(hp));
	app = hv_fetch(hp, "<init>", 6, 0);
	sig[cur++] = '(';

	if (items > 1) /* we have arguments */
		for (i = 1; i < items; i++) {
			parami = ST(i);
			if (SvROK(parami) && SvTYPE(SvRV(parami)) == SVt_PVMG) {
				tmp_param = SvIV((SV*)SvRV(parami));
				pd_param = INT2PTR(PerlDroid *, tmp_param);
				pclass = pd_param->class;
				sig[cur++] = 'L';
				cur += perl_obj_to_java_class(pclass + 11, sig + cur);
				sig[cur++] = ';';
				params[i - 1].l = (jobject) pd_param->jobj;
			} else {
				if (SvIOKp(parami)) {
					sig[cur++] = 'I';
					params[i - 1].i = (jint) SvIV(parami);
				} else if (SvNOKp(parami)) {
					sig[cur++] = 'D';
					params[i - 1].d = (jdouble) SvNV(parami);
				} else if (SvPOKp(parami)) {
					SvPV(parami, len);
					if (len == 1)
						sig[cur++] = 'C';
					else
						sig[cur++] = 's';
					params[i - 1].l = (jobject) (*my_jnienv)->NewStringUTF(my_jnienv, SvPV_nolen(parami));
				} else {
					croak("Type not recognized param #%d", i);
				}
			}
		}
	sig[cur++] = ')';
	sig[cur++] = 'V';
	sig[cur] = '\0';
	
	for (i = 0; i <= av_len((AV*)SvRV(*app)); i++) {
		proto = av_fetch((AV*)SvRV(*app), i, 0);
		proto_str = SvPV_nolen(*proto);
		warn("comp_sig %s, %s", sig, proto_str);
		if (comp_sig(sig, proto_str)) {
			fsig = 1;
			break;
		}
	}

	if (!fsig)
		croak("Signature not found");

	perl_obj_to_java_class(CLASS + 11, jclazz);

	jniClass = (*my_jnienv)->FindClass(my_jnienv, jclazz);

	if(!jniClass) {
		croak("Can't find class %s", jclazz);
	}

	jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", proto_str);
	if(!jniConstructorID) {
		croak("Can't find constructor for class %s", jclazz);
	}

	jniObject = (*my_jnienv)->NewObjectA(my_jnienv, jniClass, jniConstructorID, params);
	if(!jniObject) {
		croak("Can't instantiate class %s", jclazz);
	}

	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newSVsv((SV*)ST(0));
	ret->jobj  = jniObject;
	ret->class = strdup(CLASS);
	RETVAL = ret;

   OUTPUT:
	RETVAL

PerlDroid *
XS_method(autoload, obj, ...)
	char *autoload;
	PerlDroid *obj;
   PREINIT:
	SV** proto;
	char *proto_str;
	int i;
	int cur = 0;
	int fsig = 0;
	char* CLASS;
	SV** app;
	char sig[1024];
	char* pclass;
	STRLEN len;
	SV* parami;
	char jclazz[128];
	jclass jniClass;
	jmethodID jniConstructorID;
	jobject jniObject;
	jvalue params[128];
	PerlDroid *ret;
	IV tmp_param;
	PerlDroid *pd_param;
   CODE:
	/*CLASS = HvNAME(SvSTASH(hp));
	app = hv_fetch(hp, autoload, strlen(autoload), 0);*/
	sig[cur++] = '(';

	if (items > 2) /* we have arguments */
		for (i = 2; i < items; i++) {
			parami = ST(i);
			if (SvROK(parami) && SvTYPE(SvRV(parami)) == SVt_PVMG) {
				tmp_param = SvIV((SV*)SvRV(parami));
				pd_param = INT2PTR(PerlDroid *,tmp_param);
				pclass = pd_param->class;
				cur += perl_obj_to_java_class(pclass, sig + cur);
				params[i - 1].l = (jobject) pd_param->jobj;
			} else {
				if (SvIOKp(parami)) {
					sig[cur++] = 'I';
					params[i - 1].i = (jint) SvIV(parami);
				} else if (SvNOKp(parami)) {
					sig[cur++] = 'D';
					params[i - 1].d = (jdouble) SvNV(parami);
				} else if (SvPOKp(parami)) {
					SvPV(parami, len);
					if (len == 1)
						sig[cur++] = 'C';
					else
						sig[cur++] = 's';
					params[i - 1].l = (jobject) (*my_jnienv)->NewStringUTF(my_jnienv, SvPV_nolen(parami));
				} else {
					croak("Type not recognized param #%d", i);
				}
			}
		}
	sig[cur++] = ')';
	sig[cur++] = 'V';
	sig[cur] = '\0';
	
	for (i = 0; i <= av_len((AV*)SvRV(*app)); i++) {
		proto = av_fetch((AV*)SvRV(*app), i, 0);
		proto_str = SvPV_nolen(*proto);
		warn("comp_sig %s, %s", sig, proto_str);
		if (comp_sig(sig, proto_str)) {
			fsig = 1;
			break;
		}
	}

	if (!fsig)
		croak("Signature not found");

	perl_obj_to_java_class(CLASS + 11, jclazz);

	jniClass = (*my_jnienv)->FindClass(my_jnienv, jclazz);

	if(!jniClass) {
		croak("Can't find class %s", jclazz);
	}

	jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", proto_str);
	if(!jniConstructorID) {
		croak("Can't find constructor for class %s", jclazz);
	}

	jniObject = (*my_jnienv)->NewObjectA(my_jnienv, jniClass, jniConstructorID, params);
	if(!jniObject) {
		croak("Can't instantiate class %s", jclazz);
	}

	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs = newSVsv((SV*)ST(0));
	ret->jobj = jniObject;
	RETVAL = ret;
   OUTPUT:
	RETVAL



MODULE = PerlDroid  PACKAGE = PerlDroidPtr

void
DESTROY(perldroid)
	PerlDroid *perldroid;
	CODE:
		SvREFCNT_dec(perldroid->sigs);
		safefree(perldroid->class);
		safefree(perldroid);
