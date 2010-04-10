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
  "Ijava/lang/Integer",
  "Jjava/lang/Long",
  "Fjava/lang/Float",
  "Djava/lang/Double",
  "sjava/lang/String"
};

typedef struct {
  char *class;
  SV *sigs;
  jobject jobj;
  jobject gref;
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

static void java_class_to_perl_obj(char *java_class, char *perl_obj)
{
  char c;

  strcpy(perl_obj, "PerlDroid::");
  perl_obj += 11;

  while (c = *(java_class++)) {
    switch(c) {
    case '/':
      *(perl_obj++) = ':';
      *(perl_obj++) = ':';
      break;
    case '$':
      *(perl_obj++) = '_';
      break;
    case 'L':
    case ';':
      break;
    default:
      *(perl_obj++) = c;
      break;
    }
  }

  *perl_obj = '\0';
}

static int get_type(char **s, char *sb)
{
  switch(**s) {
  case '\0':
    break;
  case 'L':
    while ((*(sb++) = *((*s)++)) != ';')
      ;
    break;
  case ')':
    *sb = '\0';
    return 1;
    break;
  default:
    *(sb++) = *((*s)++);
    break;
  }

  *sb = '\0';
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

static char *comp_sig(char *sig, char *test_sig)
{
  char *s1, *s2, *rets;
  char sb1[128], sb2[128];
  int lo;

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
	s2++;
	ep2 = get_type(&s2, sb2);
	rets = strdup(sb2);
	return rets;
      } else
	return 0;
    }
  }

  return 0;
}

SV** get_meth_in_parent(HV *hp, char *class, char *method)
{
  SV **parent_sv, **method_sv;
  char parent_class[128];
  char *parent, *str;
  STRLEN lparent;

  warn("in get_parent for %s", method);

  parent_sv = hv_fetch(hp, "<parent>", 8, 0);
  if (!parent_sv)
    croak("Can't find method %s", method);

  parent = SvPV(*parent_sv, lparent);
  strcpy(parent_class, parent);
	
  str = parent_class + lparent;
  while (str > parent_class && *str != ':')
    str--;
  *(--str) = '\0';
  warn("in get_parent loading %s", parent_class);
  load_module(PERL_LOADMOD_NOIMPORT, newSVpv(parent_class, strlen(parent_class)), NULL);

  hp = (HV*)SvRV(get_sv(parent, FALSE));
  method_sv = hv_fetch(hp, method, strlen(method), 0);

  if (!method_sv)
    return get_meth_in_parent(hp, class, method);

  strcpy(class, parent);
  return method_sv;
}

MODULE = PerlDroid  PACKAGE = PerlDroid

PerlDroid *
XS_proxy(hp)
	HV* hp;
   PREINIT:
	char* CLASS;
	IV tmp_param;
	PerlDroid *pd_param;
	jclass jniIClass, jniPClass;
	jmethodID jniPMethodID;
	jobject jniPObject;
	PerlDroid *ret;
	SV *psigs;
	char clazz[128];
   CODE:
	CLASS = HvNAME(SvSTASH(hp));

	perl_obj_to_java_class(CLASS + 11, clazz);
	jniIClass = (*my_jnienv)->FindClass(my_jnienv, clazz);

	if (!jniIClass) {
	  croak("Can't find class p1 %s", clazz);
	}

	jniPClass = (*my_jnienv)->FindClass(my_jnienv, "org/gtmp/perl/PerlDroidProxy");

	if (!jniPClass) {
	  croak("Can't find class p2 org/gtmp/perl/PerlDroidProxy");
	}

	jniPMethodID = (*my_jnienv)->GetStaticMethodID(my_jnienv, jniPClass, "newInstance", "(Ljava/lang/Class;)Ljava/lang/Object;");
	if (!jniPMethodID) {
	  croak("Can't find method newInstance for class org/gtmp/perl/PerlDroidProxy");
	}

	warn("Instantiating Proxy");
	jniPObject = (*my_jnienv)->CallStaticObjectMethod(my_jnienv, jniPClass, jniPMethodID, jniIClass);
	if (!jniPObject) {
	  croak("Can't instantiate Proxy");
	}

	warn("Preparing return object: %s, %s", CLASS, clazz);
	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newSVsv(get_sv(CLASS, FALSE));
	ret->jobj  = jniPObject;
	ret->class = strdup(CLASS);
	ret->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret->jobj);

	RETVAL = ret;

   OUTPUT:
	RETVAL

PerlDroid *
XS_constructor(hp, ...)
	HV* hp;
   PREINIT:
	SV** proto;
	char *proto_str;
	int i;
	int cur = 0;
	char *ret_type;
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
		/*SvPV(parami, len);
		  if (len == 1) {
		  char *str;
		  sig[cur++] = 'C';
		  str = SvPV_nolen(parami);
		  params[i - 1].c = str[0];
		  } else {*/
		sig[cur++] = 's';
		params[i - 1].l = (jobject) (*my_jnienv)->NewStringUTF(my_jnienv, SvPV_nolen(parami));
		/*}*/
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
	  if (ret_type = comp_sig(sig, proto_str))
	    break;
	}

	if (!ret_type)
	  croak("Signature not found");

	perl_obj_to_java_class(CLASS + 11, jclazz);

	jniClass = (*my_jnienv)->FindClass(my_jnienv, jclazz);

	if (!jniClass) {
	  croak("Can't find class c1 %s", jclazz);
	}

	jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", proto_str);
	if (!jniConstructorID) {
	  croak("Can't find constructor for class %s", jclazz);
	}

	jniObject = (*my_jnienv)->NewObjectA(my_jnienv, jniClass, jniConstructorID, params);
	if (!jniObject) {
	  croak("Can't instantiate class %s", jclazz);
	}

	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newSVsv((SV*)ST(0));
	ret->jobj  = jniObject;
	ret->class = strdup(CLASS);
	ret->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret->jobj);
	free(ret_type);

	RETVAL = ret;

   OUTPUT:
	RETVAL

void
XS_method(method, obj, ...)
	char *method;
	PerlDroid *obj;
   PREINIT:
	SV** proto;
	char *proto_str;
	int i;
	int cur = 0;
	char *ret_type;
	char* CLASS;
	SV** app;
	char sig[1024];
	char* pclass;
	STRLEN len;
	SV* parami;
	char clazz[128];
	jclass jniClass;
	jclass ret_class;
	jclass ret_test;
	jmethodID jniMethodID;
	jobject jniObject;
	jvalue params[128];
	PerlDroid *ret;
	IV tmp_param;
	PerlDroid *pd_param;
	HV *hp;
	SV *psigs;
	PerlDroid *ret_obj;
	jint ret_int;
	jboolean ret_bool;
	jdouble ret_double;	
	const char *ret_string;
	char PCLASS[128];
   CODE:
	hp = (HV*)SvRV(obj->sigs);
	CLASS = obj->class;
	app = hv_fetch(hp, method, strlen(method), 0);
	warn("method arg class = %s", CLASS);

	if (!app)
	  app = get_meth_in_parent(hp, PCLASS, method);
	else
	  strcpy(PCLASS, CLASS);

	warn("method arg class2 = %s", PCLASS);

	sig[cur++] = '(';

	if (items > 2)
	  for (i = 2; i < items; i++) {
	    parami = ST(i);
	    if (SvROK(parami) && SvTYPE(SvRV(parami)) == SVt_PVMG) {
	      tmp_param = SvIV((SV*)SvRV(parami));
	      pd_param = INT2PTR(PerlDroid *, tmp_param);
	      pclass = pd_param->class;
	      sig[cur++] = 'L';
	      cur += perl_obj_to_java_class(pclass + 11, sig + cur);
	      sig[cur++] = ';';
	      params[i - 2].l = (jobject) pd_param->jobj;
	    } else {
	      if (SvIOKp(parami)) {
		sig[cur++] = 'I';
		params[i - 2].i = (jint) SvIV(parami);
	      } else if (SvNOKp(parami)) {
		sig[cur++] = 'D';
		params[i - 2].d = (jdouble) SvNV(parami);
	      } else if (SvPOKp(parami)) {
		/*SvPV(parami, len);
		  if (len == 1) {
		  char *str;
		  sig[cur++] = 'C';
		  str = SvPV_nolen(parami);
		  params[i - 2].c = str[0];
		  } else {*/
		sig[cur++] = 's';
		params[i - 2].l = (jobject) (*my_jnienv)->NewStringUTF(my_jnienv, SvPV_nolen(parami));
		/*}*/
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
	  if (ret_type = comp_sig(sig, proto_str))
	    break;
	}

	if (!ret_type)
	  croak("Signature not found");

	warn("ret_type=%s", ret_type);

	perl_obj_to_java_class(PCLASS + 11, clazz);
	jniClass = (*my_jnienv)->FindClass(my_jnienv, clazz);
	if (!jniClass) {
	  croak("Can't find class m1 %s", clazz);
	}

	jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, method, proto_str);
	if (!jniMethodID) {
	  croak("Can't find method %s for class %s", method, clazz);
	}

	switch(ret_type[0]) {
	case 'L':
	  ret_type[strlen(ret_type) - 1] = '\0';
	  ret_class = (*my_jnienv)->FindClass(my_jnienv, ret_type + 1);
	  if (!ret_class) {
	    croak("Can't find class m2 %s", ret_type + 1);
	  }
	  
	  jniObject = (*my_jnienv)->CallObjectMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  if (!jniObject) {
	    croak("Can't call method %s", method);
	  }
	  
	  ret_test  = (*my_jnienv)->FindClass(my_jnienv, "java/lang/CharSequence");
	  if ((*my_jnienv)->IsAssignableFrom(my_jnienv, ret_class, ret_test)) {
	    ret_string = (*my_jnienv)->GetStringUTFChars(my_jnienv, (jstring) jniObject, NULL);
	    ST(0) = newSVpv(ret_string, 0);
	    sv_2mortal(ST(0));
	    (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, (jstring) jniObject, ret_string);
	  } else {
	    ret_obj = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	    java_class_to_perl_obj(ret_type, clazz);
	    ret_obj->jobj  = jniObject;
	    ret_obj->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret_obj->jobj);
	    ret_obj->class = strdup(clazz);
	    psigs = get_sv(clazz, FALSE);
	    if (!psigs) {
	      char *str = clazz + strlen(clazz);
	      while (str > clazz && *str != ':')
		str--;
	      *(--str) = '\0';
	      load_module(PERL_LOADMOD_NOIMPORT, newSVpv(clazz, strlen(clazz)), NULL);
	      psigs = get_sv(clazz, FALSE);
	      if (!psigs)
		croak("Can't load module %s", clazz);
	    }
	    ret_obj->sigs = newSVsv(psigs);
	    ST(0) = sv_newmortal();
	    sv_setref_pv(ST(0), "PerlDroidPtr", (void*)ret_obj);
	  }
	  break;
	  
	case 'I':
	case 'B':
	case 'S':
	case 'J':
	  ret_int = (*my_jnienv)->CallIntMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSViv(ret_int);
	  sv_2mortal(ST(0));
	  break;
	case 'F':
	case 'D':
	  ret_double = (*my_jnienv)->CallDoubleMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSVnv(ret_double);
	  sv_2mortal(ST(0));
	  break;
	case 'V':
	  (*my_jnienv)->CallVoidMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  XSRETURN_UNDEF;
	  break;
	case 'Z':
	  ret_bool = (*my_jnienv)->CallBooleanMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSViv(ret_bool ? 1 : 0);
	  sv_2mortal(ST(0));
	  break;
	default:
	  croak("Bug in ret type: %s", ret_type);
	  break;
	}
	free(ret_type);

MODULE = PerlDroid  PACKAGE = PerlDroidPtr

void
DESTROY(perldroid)
	PerlDroid *perldroid;
   CODE:
	SvREFCNT_dec(perldroid->sigs);
	free(perldroid->class);
	(*my_jnienv)->DeleteGlobalRef(my_jnienv, perldroid->gref);
	safefree(perldroid);
