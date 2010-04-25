#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <jni.h>
#include <string.h>
#include "PerlDroid.h"

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

static module2file(char *clazz, char *clazzpm)
{
  while(*clazz) {
    switch(*clazz) {
    case ':':
      *(clazzpm++) = '/';
      clazz++;
      break;
    default:
      *(clazzpm++) = *clazz;;
      break;
    }
    clazz++;
  }
  *clazzpm = '\0';
  strcat(clazzpm, ".pm");
}

static char *my_strdup(char *str)
{
  char *ret = safemalloc(strlen(str) + 1);
  strcpy(ret, str);
  return ret;
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

  if (*t1 == 'N')
    return 1;

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

  if (!ok) {
    if (*t1 == 'C') {
      jc1 = (*my_jnienv)->FindClass(my_jnienv, "java/lang/String");
      ok = (*my_jnienv)->IsAssignableFrom(my_jnienv, jc1, jc2);
    } else if (*t1 == 'I' && *t2 == 'Z') {
      ok = 1;
    }
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

  if (*(sig + 1) == '[' || *(test_sig + 1) == '[')
    return 0;

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
	rets = my_strdup(sb2);
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
  char classpm[128];

  warn("in get_parent for %s - %p", method, hp);

  parent_sv = hv_fetch(hp, "<parent>", 8, 0);
  if (!parent_sv)
    croak("Can't find method %s", method);
  warn("in get_parent fetched <parent>");
  //sv_2mortal(*parent_sv);

  parent = SvPV(*parent_sv, lparent);
  strcpy(parent_class, parent);
	
  str = parent_class + lparent;
  while (str > parent_class && *str != ':')
    str--;
  *(--str) = '\0';
  module2file(parent_class, classpm);
  warn("in get_parent loading %s => %s", parent_class, classpm);
  require_pv(classpm);

  hp = (HV*)SvRV(get_sv(parent, FALSE));
  method_sv = hv_fetch(hp, method, strlen(method), 0);

  if (!method_sv)
    return get_meth_in_parent(hp, class, method);

  //  sv_2mortal(*method_sv);
  strcpy(class, parent);
  return method_sv;
}

static void
perl_args_to_java_args(SV *parami, int num_param, jvalue params[], char sig[], int *cur)
{
  IV tmp_param;
  PerlDroid *pd_param;
  char *pclass;
  char *jclazz;

  warn("num_param=%d, cur=%d", num_param, (*cur));

  if (SvROK(parami) && SvTYPE(SvRV(parami)) == SVt_PVMG) {
    tmp_param = SvIV((SV*)SvRV(parami));
    pd_param = INT2PTR(PerlDroid *, tmp_param);
    jclazz = pd_param->jclass;

    sig[(*cur)++] = 'L';
    if (jclazz && *jclazz) {
      strcpy(sig + (*cur), jclazz);
      (*cur) += strlen(jclazz);
    } else {
      pclass = pd_param->pclass;
      (*cur) += perl_obj_to_java_class(pclass + 11, sig + (*cur));
    }
    sig[(*cur)++] = ';';

    params[num_param].l = (jobject) pd_param->jobj;
  } else if (SvROK(parami) && SvTYPE(SvRV(parami))==SVt_PVHV) {
    STRLEN lparent;
    char parent_class[128];
    char *parent, *str;
    HV *hp = (HV*)SvRV(parami);
    SV **parent_sv = hv_fetch(hp, "<parent>", 8, 0);
    char classpm[128];

    if (!parent_sv)
      croak("Can't find parent for param #%d", num_param);
    warn("fetched <parent> for param #%d", num_param);
    //sv_2mortal(*parent_sv);

    parent = SvPV(*parent_sv, lparent);
    strcpy(parent_class, parent);
	
    str = parent_class + lparent;
    while (str > parent_class && *str != ':')
      str--;
    *(--str) = '\0';
    module2file(parent_class, classpm);
    warn("loading %s => %s", parent_class, classpm);
    require_pv(classpm);

    perl_args_to_java_args(*parent_sv, num_param, params, sig, cur);
  } else {
    if (SvIOKp(parami)) {
      sig[(*cur)++] = 'I';
      params[num_param].i = (jint) SvIV(parami);
      warn("Type INT param #%d", num_param);
    } else if (SvNOKp(parami)) {
      sig[(*cur)++] = 'D';
      params[num_param].d = (jdouble) SvNV(parami);
    } else if (SvPOKp(parami)) {
      /*SvPV(parami, len);
	if (len == 1) {
	char *str;
	sig[(*cur)++] = 'C';
	str = SvPV_nolen(parami);
	params[i - 1].c = str[0];
	} else {*/
      sig[(*cur)++] = 's';
      params[num_param].l = (jobject) (*my_jnienv)->NewStringUTF(my_jnienv, SvPV_nolen(parami));
      /*}*/
    } else {
      params[num_param].l = NULL;
      sig[(*cur)++] = 'N';
      warn("Type not recognized or undef param #%d", num_param);
    }
  }
}

MODULE = PerlDroid  PACKAGE = PerlDroid

PerlDroid *
XS_cast(from, hp)
	PerlDroid* from;
	HV* hp;
   PREINIT:
	char *toClass;
	PerlDroid *ret;
   CODE:
	toClass = HvNAME(SvSTASH(hp));

	warn("Preparing to return cast object: %s", toClass);

	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newRV_inc((SV*)hp);
	ret->jobj  = from->jobj;
	ret->jclass = my_strdup(toClass);
	ret->pclass = my_strdup(from->pclass);
	ret->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret->jobj);

	RETVAL = ret;

   OUTPUT:
	RETVAL

PerlDroid *
XS_castObj(from, toClass)
	PerlDroid *from;
	char *toClass;
   PREINIT:
	PerlDroid *ret;
   CODE:
	warn("Preparing to return cast object: %s", toClass);

	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newRV_inc(SvRV(from->sigs));
	ret->jobj  = from->jobj;
	ret->jclass = my_strdup(from->jclass);
	ret->pclass = my_strdup(toClass);
	ret->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret->jobj);

	RETVAL = ret;

   OUTPUT:
	RETVAL

PerlDroid *
XS_proxy(class_str, pkg)
	char *class_str;
	char *pkg;
   PREINIT:
	char *pkgdup, *class_strdup;
	char* CLASS;
	IV tmp_param;
	jclass jniPClass;
	jmethodID jniPMethodID;
	jobject jniPObject;
	PerlDroid *ret;
	SV *psigs;
	char clazz[128];
	jstring jpkg, jclass_str;
   CODE:
	jniPClass = (*my_jnienv)->FindClass(my_jnienv, "org/gtmp/perl/PerlDroidProxy");

	if (!jniPClass) {
	  croak("Can't find class p2 org/gtmp/perl/PerlDroidProxy");
	}

	jniPMethodID = (*my_jnienv)->GetStaticMethodID(my_jnienv, jniPClass, "newInstanceInterface", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Object;");
	if (!jniPMethodID) {
	  croak("Can't find method newInstance for class org/gtmp/perl/PerlDroidProxy");
	}

	warn("Preparing strings");
	warn("interface=%s", class_str);
	class_strdup = my_strdup(class_str);
	jclass_str = (*my_jnienv)->NewStringUTF(my_jnienv, class_strdup);
	pkgdup = my_strdup(pkg);
	jpkg = (*my_jnienv)->NewStringUTF(my_jnienv, pkgdup);

	warn("Instantiating Proxy");
	jniPObject = (*my_jnienv)->CallStaticObjectMethod(my_jnienv, jniPClass, jniPMethodID, jclass_str, jpkg);
	if (!jniPObject) {
	  croak("Can't instantiate Proxy");
	}

	(*my_jnienv)->ReleaseStringUTFChars(my_jnienv, jclass_str, class_strdup);
	(*my_jnienv)->ReleaseStringUTFChars(my_jnienv, jpkg, pkgdup);

	warn("Preparing return object: %s, %s", class_str, pkg);
	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newSVsv(get_sv("BUG_NO_SIGS", FALSE));
	ret->jobj  = jniPObject;
	ret->jclass = my_strdup(class_str);
	ret->pclass = my_strdup(pkg);
	ret->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret->jobj);

	RETVAL = ret;

   OUTPUT:
	RETVAL

PerlDroid *
XS_implements(hp, pkg)
	HV* hp;
	char* pkg;
   PREINIT:
	char *pkgdup;
	char* CLASS;
	IV tmp_param;
	jclass jniIClass, jniPClass;
	jmethodID jniPMethodID;
	jobject jniPObject;
	PerlDroid *ret;
	SV *psigs;
	char clazz[128];
	jstring jpkg;
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

	jniPMethodID = (*my_jnienv)->GetStaticMethodID(my_jnienv, jniPClass, "newInstance", "(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/Object;");
	if (!jniPMethodID) {
	  croak("Can't find method newInstance for class org/gtmp/perl/PerlDroidProxy");
	}

	pkgdup = my_strdup(pkg);
	jpkg = (*my_jnienv)->NewStringUTF(my_jnienv, pkgdup);

	warn("Instantiating Proxy");
	jniPObject = (*my_jnienv)->CallStaticObjectMethod(my_jnienv, jniPClass, jniPMethodID, jniIClass, jpkg);
	if (!jniPObject) {
	  croak("Can't instantiate Proxy");
	}

	(*my_jnienv)->ReleaseStringUTFChars(my_jnienv, jpkg, pkgdup);

	warn("Preparing return object: %s, %s", CLASS, clazz);
	ret = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	ret->sigs  = newSVsv(get_sv(CLASS, FALSE));
	ret->jobj  = jniPObject;
	ret->jclass = my_strdup(CLASS);
	ret->pclass = my_strdup("PROXY_BUG_NO_PCLASS");
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
   CODE:
	CLASS = HvNAME(SvSTASH(hp));
	app = hv_fetch(hp, "<init>", 6, 0);
	sig[cur++] = '(';

	warn("XS:sp=[%p],mark=[%p],base=[%p] => %d", sp, *PL_markstack_ptr, PL_stack_base, (sp-((*PL_markstack_ptr) + PL_stack_base)));

	if (items > 1) /* we have arguments */
	  for (i = 1; i < items; i++) {
	    parami = ST(i);
	    perl_args_to_java_args(parami, i - 1, params, sig, &cur);
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
	ret->jclass = my_strdup(jclazz);
	ret->pclass = my_strdup(CLASS);
	ret->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret->jobj);
	safefree(ret_type);

	warn("XS2:sp=[%p],mark=[%p],base=[%p] => %p", sp, *PL_markstack_ptr, PL_stack_base, (sp-((*PL_markstack_ptr) + PL_stack_base)));
	RETVAL = ret;

   OUTPUT:
	RETVAL

void
XS_static(method, hp, ...)
	char *method;
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
	jmethodID jniStaticID;
	jobject jniObject;
	jvalue params[128];
	PerlDroid *ret;
	IV tmp_param;
	SV *psigs;
	jclass ret_class;
	jclass ret_test;
	PerlDroid *ret_obj;
	jint ret_int;
	jboolean ret_bool;
	jdouble ret_double;	
	const char *ret_string;
	char clazz[128];
   PPCODE:
	CLASS = HvNAME(SvSTASH(hp));
	app = hv_fetch(hp, method, strlen(method), 0);

	warn("static: method = %s, class = %s", method, CLASS);

	sig[cur++] = '(';

	if (items > 2) /* we have arguments */
	  for (i = 2; i < items; i++) {
	    parami = ST(i);
	    perl_args_to_java_args(parami, i - 2, params, sig, &cur);
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

	perl_obj_to_java_class(CLASS + 11, jclazz);

	if (!ret_type)
	  croak("Signature not found method %s for class %s", method, jclazz);

	jniClass = (*my_jnienv)->FindClass(my_jnienv, jclazz);

	if (!jniClass) {
	  croak("Can't find class c1 %s", jclazz);
	}

	jniStaticID = (*my_jnienv)->GetStaticMethodID(my_jnienv, jniClass, method, proto_str);
	if (!jniStaticID) {
	  croak("Can't find static method %s for class %s", method, jclazz);
	}

	switch(ret_type[0]) {
	case 'L':
	  ret_type[strlen(ret_type) - 1] = '\0';
	  ret_class = (*my_jnienv)->FindClass(my_jnienv, ret_type + 1);
	  if (!ret_class) {
	    croak("Can't find class m2 %s", ret_type + 1);
	  }
	  
	  jniObject = (*my_jnienv)->CallStaticObjectMethodA(my_jnienv, jniClass, jniStaticID, params);
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
	    char clazzpm[128];

	    ret_obj = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	    java_class_to_perl_obj(ret_type, clazz);
	    ret_obj->jobj  = jniObject;
	    ret_obj->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret_obj->jobj);
	    ret_obj->jclass = my_strdup(ret_type + 1);
	    ret_obj->pclass = my_strdup(clazz);
	    psigs = get_sv(clazz, FALSE);
	    if (!psigs) {
	      char *str = clazz + strlen(clazz);
	      while (str > clazz && *str != ':')
		str--;
	      *(--str) = '\0';
	      module2file(clazz, clazzpm);
	      require_pv(clazzpm);
	      *str = ':';
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
	  ret_int = (*my_jnienv)->CallStaticIntMethodA(my_jnienv, jniClass, jniStaticID, params);
	  ST(0) = newSViv(ret_int);
	  sv_2mortal(ST(0));
	  break;
	case 'F':
	case 'D':
	  ret_double = (*my_jnienv)->CallStaticDoubleMethodA(my_jnienv, jniClass, jniStaticID, params);
	  ST(0) = newSVnv(ret_double);
	  sv_2mortal(ST(0));
	  break;
	case 'V':
	  (*my_jnienv)->CallStaticVoidMethodA(my_jnienv, jniClass, jniStaticID, params);
	  ST(0) = newSV(0);
	  sv_2mortal(ST(0));
	  break;
	case 'Z':
	  ret_bool = (*my_jnienv)->CallStaticBooleanMethodA(my_jnienv, jniClass, jniStaticID, params);
	  ST(0) = newSViv(ret_bool ? 1 : 0);
	  sv_2mortal(ST(0));
	  break;
	default:
	  croak("Bug in ret type: %s", ret_type);
	  break;
	}
	safefree(ret_type);
	XSRETURN(1);

void
XS_method(method, super, obj, ...)
	char *method;
	int super;
	PerlDroid *obj;
   PREINIT:
	SV** proto;
	char *proto_str;
	int i;
	int cur = 0;
	char *ret_type;
	char* CLASS;
	SV** app = NULL;
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
	HV *hp;
	SV *psigs;
	PerlDroid *ret_obj;
	jint ret_int;
	jboolean ret_bool;
	jdouble ret_double;	
	const char *ret_string;
	char PCLASS[128];
	SV **is_perl = NULL;
	int pm = 1;
	jclass spclass;
   PPCODE:
	warn("method %s arg = %p - %p - %p", method, obj, obj->sigs, obj->jobj);
	CLASS = obj->pclass;
	warn("method arg class = %s", CLASS);

	warn("XS3:sp=[%p],mark=[%p],base=[%p] => %p", sp, *PL_markstack_ptr, PL_stack_base, (sp-((*PL_markstack_ptr) + PL_stack_base)));
	if (strncmp(CLASS, "PerlDroid::", 11) && *(obj->jclass)) {
	  PCLASS[0] = '\0';
	  strcpy(clazz, obj->jclass);
	  pm = 0;
	}

	if (obj->sigs && SvROK(obj->sigs) && SvTYPE(SvRV(obj->sigs))==SVt_PVHV) {
	  warn("looking at sigs for <perl>");
	  hp = (HV*)SvRV(obj->sigs);
	  is_perl = hv_fetch(hp, "<perl>", 6, 0);
	  warn("<perl>=%p", is_perl);

	  if (is_perl)
	    app = get_meth_in_parent(hp, PCLASS, method);
	  else {
	    app = hv_fetch(hp, method, strlen(method), 0);
	    warn("app=%p", app);
	  }
	}

	if (app) {
	  if (pm)
	    strcpy(PCLASS, CLASS);
	  else
	    java_class_to_perl_obj(clazz, PCLASS);
	} else {
	  char tpclass[128], classpm[128];
	  char *str;

	  warn("is PerlDroid*");
	  strcpy(PCLASS, CLASS);
	  strcpy(tpclass, CLASS);

	  str = tpclass + strlen(tpclass);
	  while (*str != ':' && str > tpclass)
	    str--;
	  if (str != tpclass)
	    *(--str) = '\0';

	  warn("loading module %s", tpclass);
	  module2file(tpclass, classpm);
	  warn("loading module %s (%s)", tpclass, classpm);
	  require_pv(classpm);
	  psigs = get_sv(PCLASS, FALSE);
	  if (!psigs)
	    croak("Can't find faked class %s", PCLASS);

	  hp = (HV*)SvRV(psigs);
	  app = hv_fetch(hp, method, strlen(method), 0);
	  warn("method hp=%p, app=%p", hp, app);
	  
	  if (!app)
	    app = get_meth_in_parent(hp, PCLASS, method);
	}

	warn("method arg class2 = %s, app=%p", PCLASS, app);

	sig[cur++] = '(';

	if (items > 3)
	  for (i = 3; i < items; i++) {
	    parami = ST(i);
	    perl_args_to_java_args(parami, i - 3, params, sig, &cur);
	  }

	sig[cur++] = ')';
	sig[cur++] = 'V';
	sig[cur] = '\0';
	
	warn("before comp_sig, sig=%s", sig);
	for (i = 0; i <= av_len((AV*)SvRV(*app)); i++) {
	  warn("comp_sig i=%d", i);
	  proto = av_fetch((AV*)SvRV(*app), i, 0);
	  warn("comp_sig2 proto=%p", proto);
	  proto_str = SvPV_nolen(*proto);
	  warn("comp_sig %s, %s", sig, proto_str);
	  if (ret_type = comp_sig(sig, proto_str))
	    break;
	}

	if (!ret_type)
	  croak("Signature not found");

	warn("ret_type=%s", ret_type);

	perl_obj_to_java_class(PCLASS + 11, clazz);

	warn("method arg class3 = %s", clazz);

	jniClass = (*my_jnienv)->FindClass(my_jnienv, clazz);
	if (!jniClass) {
	  croak("Can't find class m1 %s", clazz);
	}

	if (super) {
	  warn("super=%d", super);
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
	  
	  if (super)
	    jniObject = (*my_jnienv)->CallNonvirtualObjectMethodA(my_jnienv, obj->jobj, jniClass, jniMethodID, params);
	  else
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
	    char clazzpm[128];

	    ret_obj = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	    java_class_to_perl_obj(ret_type, clazz);
	    ret_obj->jobj  = jniObject;
	    ret_obj->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, ret_obj->jobj);
	    ret_obj->jclass = my_strdup(ret_type + 1);
	    warn("pclass %s, %d", clazz, strlen(clazz));
	    ret_obj->pclass = my_strdup(clazz);
	    warn("pclass %s", ret_obj->pclass);
	    psigs = get_sv(clazz, FALSE);
	    if (!psigs) {
	      char *str = clazz + strlen(clazz);
	      while (str > clazz && *str != ':')
		str--;
	      *(--str) = '\0';
	      module2file(clazz, clazzpm);
	      warn("loading module %s (%s) for class %s", clazz, clazzpm, ret_obj->pclass);
	      require_pv(clazzpm);
	      *str = ':';
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
	  if (super)
	    ret_int = (*my_jnienv)->CallNonvirtualIntMethodA(my_jnienv, obj->jobj, jniClass, jniMethodID, params);
	  else
	    ret_int = (*my_jnienv)->CallIntMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSViv(ret_int);
	  sv_2mortal(ST(0));
	  break;
	case 'F':
	case 'D':
	  if (super)
	    ret_double = (*my_jnienv)->CallNonvirtualDoubleMethodA(my_jnienv, obj->jobj, jniClass, jniMethodID, params);
	  else
	    ret_double = (*my_jnienv)->CallDoubleMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSVnv(ret_double);
	  sv_2mortal(ST(0));
	  break;
	case 'V':
	  if (super)
	    (*my_jnienv)->CallNonvirtualVoidMethodA(my_jnienv, obj->jobj, jniClass, jniMethodID, params);
	  else
	    (*my_jnienv)->CallVoidMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSV(0);
	  sv_2mortal(ST(0));
	  break;
	case 'Z':
	  if (super)
	    ret_bool = (*my_jnienv)->CallNonvirtualBooleanMethodA(my_jnienv, obj->jobj, jniClass, jniMethodID, params);
	  else
	    ret_bool = (*my_jnienv)->CallBooleanMethodA(my_jnienv, obj->jobj, jniMethodID, params);
	  ST(0) = newSViv(ret_bool ? 1 : 0);
	  sv_2mortal(ST(0));
	  break;
	default:
	  croak("Bug in ret type: %s", ret_type);
	  break;
	}
	safefree(ret_type);
	warn("XS4:sp=[%p],mark=[%p],base=[%p] => %p", sp, *PL_markstack_ptr, PL_stack_base, (sp-((*PL_markstack_ptr) + PL_stack_base)));
	XSRETURN(1);

MODULE = PerlDroid  PACKAGE = PerlDroidPtr

void
DESTROY(perldroid)
	PerlDroid *perldroid;
   CODE:
	SvREFCNT_dec(perldroid->sigs);
	safefree(perldroid->jclass);
	safefree(perldroid->pclass);
	(*my_jnienv)->DeleteGlobalRef(my_jnienv, perldroid->gref);
	safefree(perldroid);
