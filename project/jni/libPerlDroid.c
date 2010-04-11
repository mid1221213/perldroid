#include "JNIHelp.h"
#include <stdio.h>
#include <stdlib.h>
#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
#include <dlfcn.h>
#include "PerlDroid.h"

#define LOG_TAG "libPerlDroid"
#include "android/log.h"
#define LOGV2(fmt, arg) __android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, fmt, arg)
#define LOGE2(fmt, arg) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, fmt, arg)
#define LOGE3(fmt, arg1, arg2) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, fmt, arg1, arg2)

#define CLASSNAME "org/gtmp/perl/JNIStub"

static PerlInterpreter *my_perl;  /***    The Perl interpreter    ***/

static void *lp_h;

static void (*my_Perl_sys_init)(int*, char***);
static PerlInterpreter * (*my_perl_alloc)(void);
static int (*my_perl_construct)(pTHX);
static int (*my_perl_destruct)(pTHX);
static int (*my_perl_parse)(pTHXx_ XSINIT_t, int, char **, char **);
static int (*my_perl_run)(pTHXx);
static SV* (*my_Perl_eval_pv)(pTHX_ const char *, I32);
static void (*my_Perl_sys_term)(void);
static void (*my_perl_free)(pTHXx);
static SV* (*my_Perl_get_sv)(pTHX_ const char *, I32);
static IV (*my_Perl_sv_2iv_flags)(pTHX_ SV*, I32);
static SV* (*my_Perl_sv_2mortal)(pTHX_ SV* sv);
static Malloc_t	(*my_Perl_safesysmalloc)(MEM_SIZE nbytes);
static SV *(*my_Perl_newSVsv)(pTHX_ SV* old);
static SV *(*my_Perl_sv_setref_pv)(pTHX_ SV* rv, const char* classname, void* pv);
static int (*my_Perl_call_sv)(pTHX_ SV* sv, I32 flags);
static CV* (*my_Perl_newXS)(pTHX_ const char*, XSUBADDR_t, const char*);
static CV* (*my_Perl_get_cv)(pTHX_ const char* name, I32 flags);

static void (*my_Perl_push_scope)(pTHX);
static void (*my_Perl_save_int)(pTHX_ int* intp);
static void (*my_Perl_markstack_grow)(pTHX);
static SV** (*my_Perl_stack_grow)(pTHX_ SV** sp, SV** p, int n);
static SV* (*my_Perl_newSViv)(pTHX_ IV i);
static SV* (*my_Perl_newSVnv)(pTHX_ NV n);
static SV* (*my_Perl_newSVpv)(pTHX_ const char* s, STRLEN len);
static SV* (*my_Perl_sv_newmortal)(pTHX);
static NV (*my_Perl_sv_2nv)(pTHX_ SV* sv);
static char* (*my_Perl_sv_2pv_flags)(pTHX_ SV* sv, STRLEN* lp, I32 flags);
static void (*my_Perl_free_tmps)(pTHX);
static void (*my_Perl_pop_scope)(pTHX);
static void (*my_Perl_croak_nocontext)(const char *pat, ...);
static void (*my_Perl_warn_nocontext)(const char *pat, ...);

static void (*my_boot_DynaLoader)(pTHX_ CV* cv);

#define Perl_get_sv my_Perl_get_sv
#define Perl_sv_2iv_flags my_Perl_sv_2iv_flags
#define Perl_sv_2mortal my_Perl_sv_2mortal
#define Perl_newXS  my_Perl_newXS
#define Perl_safesysmalloc my_Perl_safesysmalloc
#define Perl_newSVsv my_Perl_newSVsv
#define Perl_call_sv my_Perl_call_sv
#define Perl_sv_setref_pv my_Perl_sv_setref_pv
#define Perl_get_cv my_Perl_get_cv
#define Perl_push_scope my_Perl_push_scope
#define Perl_save_int my_Perl_save_int
#define Perl_markstack_grow my_Perl_markstack_grow
#define Perl_stack_grow my_Perl_stack_grow
#define Perl_newSViv my_Perl_newSViv
#define Perl_newSVnv my_Perl_newSVnv
#define Perl_newSVpv my_Perl_newSVpv
#define Perl_sv_newmortal my_Perl_sv_newmortal
#define Perl_sv_2nv my_Perl_sv_2nv
#define Perl_sv_2pv_flags my_Perl_sv_2pv_flags
#define Perl_free_tmps my_Perl_free_tmps
#define Perl_pop_scope my_Perl_pop_scope
#define Perl_croak_nocontext my_Perl_croak_nocontext
#define Perl_warn_nocontext my_Perl_warn_nocontext

JNIEnv *my_jnienv;

int
open_libperl_so(void)
{
  lp_h = dlopen("/data/data/org.gtmp.perl/lib/libperl.so", RTLD_LAZY);
  
  if (lp_h) {
    my_Perl_sys_init        = dlsym(lp_h, "Perl_sys_init");
    my_perl_alloc           = dlsym(lp_h, "perl_alloc");
    my_perl_construct       = dlsym(lp_h, "perl_construct");
    my_perl_destruct        = dlsym(lp_h, "perl_destruct");
    my_perl_parse           = dlsym(lp_h, "perl_parse");
    my_perl_run             = dlsym(lp_h, "perl_run");
    my_Perl_eval_pv         = dlsym(lp_h, "Perl_eval_pv");
    my_perl_free            = dlsym(lp_h, "perl_free");
    my_Perl_sys_term        = dlsym(lp_h, "Perl_sys_term");
    my_Perl_get_sv          = dlsym(lp_h, "Perl_get_sv");
    my_Perl_sv_2iv_flags    = dlsym(lp_h, "Perl_sv_2iv_flags");
    my_Perl_sv_2mortal      = dlsym(lp_h, "Perl_sv_2mortal");
    my_Perl_newXS           = dlsym(lp_h, "Perl_newXS");
    my_Perl_safesysmalloc   = dlsym(lp_h, "Perl_safesysmalloc");
    my_Perl_newSVsv         = dlsym(lp_h, "Perl_newSVsv");
    my_Perl_call_sv         = dlsym(lp_h, "Perl_call_sv");
    my_Perl_sv_setref_pv    = dlsym(lp_h, "Perl_sv_setref_pv");
    my_Perl_get_cv          = dlsym(lp_h, "Perl_get_cv");
    my_Perl_push_scope      = dlsym(lp_h, "Perl_push_scope");
    my_Perl_save_int        = dlsym(lp_h, "Perl_save_int");
    my_Perl_markstack_grow  = dlsym(lp_h, "Perl_markstack_grow");
    my_Perl_stack_grow      = dlsym(lp_h, "Perl_stack_grow");
    my_Perl_newSViv         = dlsym(lp_h, "Perl_newSViv");
    my_Perl_newSVnv         = dlsym(lp_h, "Perl_newSVnv");
    my_Perl_newSVpv         = dlsym(lp_h, "Perl_newSVpv");
    my_Perl_sv_newmortal    = dlsym(lp_h, "Perl_sv_newmortal");
    my_Perl_sv_2nv          = dlsym(lp_h, "Perl_sv_2nv");
    my_Perl_sv_2pv_flags    = dlsym(lp_h, "Perl_sv_2pv_flags");
    my_Perl_free_tmps       = dlsym(lp_h, "Perl_free_tmps");
    my_Perl_pop_scope       = dlsym(lp_h, "Perl_pop_scope");
    my_Perl_croak_nocontext = dlsym(lp_h, "Perl_croak_nocontext");
    my_Perl_warn_nocontext  = dlsym(lp_h, "Perl_warn_nocontext");
    my_boot_DynaLoader      = dlsym(lp_h, "boot_DynaLoader");
  } else
    return 0;

  return 1;
}

void
close_libperl_so(void)
{
  dlclose(lp_h);
}

EXTERN_C void
xs_init(pTHX)
{
  char *file = __FILE__;
  /* DynaLoader is a special case */
  newXS("DynaLoader::boot_DynaLoader", my_boot_DynaLoader, file);
}

jint
run_perl(JNIEnv *env, jclass cls, jobject this, jstring clazz, jstring script, jstring path)
{
  my_jnienv = env;
  jint ret = -1;
  int argc = 3;
  char *argv[4];
  SV *pthis, *ppthis;
  PerlDroid *param;
  const char *script_path;
  const char *inc_path;
  char *clazz_name;
  char clazz_perl[128];
  char include[128];
  char *str;

  if (open_libperl_so()) {
    script_path = (*my_jnienv)->GetStringUTFChars(my_jnienv, script, NULL);
    inc_path = (*my_jnienv)->GetStringUTFChars(my_jnienv, path, NULL);
    clazz_name  = (char *)((*my_jnienv)->GetStringUTFChars(my_jnienv, clazz, NULL));

    str = clazz_name;
    while (*str) {
      if (*str == '.')
	*str = '/';
      str++;
    }

    java_class_to_perl_obj(clazz_name, clazz_perl);

    sprintf(include, "-I%s", inc_path);

    argv[0] = "org.gtmp.perl";
    argv[1] = include;
    argv[2] = (char *) script_path;
    argv[3] = NULL;

    my_Perl_sys_init(&argc, (char ***) &argv);
    my_perl = my_perl_alloc();
    PL_perl_destruct_level = 1;
    my_perl_construct(my_perl);
    
    my_perl_parse(my_perl, xs_init, argc, argv, NULL);

    pthis  = get_sv("this", TRUE);
    ppthis = get_sv(clazz_perl, FALSE);

    param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
    param->sigs  = newSVsv(ppthis);
    param->jobj  = this;
    param->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, param->jobj);
    param->class = strdup(clazz_perl);
    sv_setref_pv(pthis, "PerlDroidPtr", (void*)param);

    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    ret = my_perl_run(my_perl);

    (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, script, script_path);
    (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, path, inc_path);
    (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, clazz, clazz_name);

    // Don't destruct interpreter because of possible callbacks

/*     PL_perl_destruct_level = 1; */
/*     my_perl_destruct(my_perl); */
/*     my_perl_free(my_perl); */
/*     my_Perl_sys_term(); */

/*     close_libperl_so(); */
  }

  return ret;
}

void chmodr(const char* path) {
  int i;
  int nfiles;
  struct dirent** dirlist;

  chmod(path, 0755);
  nfiles = scandir(path, &dirlist, NULL, NULL);
  for (i = 0; i < nfiles; i++) {
    char buf[256];
    sprintf(buf, "%s/%s", path, dirlist[i]->d_name);
    /* recurse only if it is not . nor .. */
    if (strcmp(dirlist[i]->d_name, ".") &&
	strcmp(dirlist[i]->d_name, "..")) {
      if (dirlist[i]->d_type == DT_DIR)
	chmodr(buf);
      else
	chmod(buf, 0755);
    }
  }
}

static jobject
run_chmod(JNIEnv *env, jclass clazz, jstring path_string)
{
  const char *path;
  my_jnienv = env;
  path = (*my_jnienv)->GetStringUTFChars(my_jnienv, path_string, NULL);

  chmodr(path);

  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, path_string, path);
}

static jobject
run_callback(JNIEnv *env, jclass clazz, jstring clazz_name, jstring m, jobjectArray args)
{
  dSP;
  int count;
  SV *ret;
  IV tmp_param;
  PerlDroid *pd_param;
  jobject tmp_obj, tmp_obj2, ret_obj;
  const char *method;
  CV *sub;
  jclass jniClass, jniObjClass, jniClassClass, jniIntClass, jniDblClass;
  jmethodID jniConstructorID, jniMethodID;
  char *from_className;
  const char *className;
  jsize args_len;
  char arg_type[128], parg_type[128], fromPerlPkg[128];
  int lo;
  int arg_int;
  double arg_double;
  const char *arg_str;
  jobject arg_obj;
  PerlDroid *arg_pobj;
  SV *arg_sv, *psigs;
  char *src, *dst;

  my_jnienv = env;

  args_len = (*my_jnienv)->GetArrayLength(my_jnienv, args);

  from_className = (char *)(*my_jnienv)->GetStringUTFChars(my_jnienv, clazz_name, NULL);
  method = (*my_jnienv)->GetStringUTFChars(my_jnienv, m, NULL);

  warn("frompkg=[%s]", from_className);
  if (!strncmp(from_className, "[PKG]", 5)) {
    strcpy(fromPerlPkg, from_className + 5);
  } else {
    strcpy(fromPerlPkg, "PerlDroid::");
    for (src = (char *) from_className, dst = fromPerlPkg + 11; *src; src++)
      if (*src == '.') {
	*dst++ = ':';
	*dst++ = ':';
      } else if (*src == '$') {
	*dst++ = '_';
      } else
	*dst++ = *src;
    *dst = '\0';
  }

  strcpy(fromPerlPkg + strlen(fromPerlPkg), "::");
  strcpy(fromPerlPkg + strlen(fromPerlPkg), method);

  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, clazz_name, from_className);
  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, m, method);

  sub = get_cv(fromPerlPkg, 0);

  if (!sub)
    croak("Method %s not found", fromPerlPkg);

  jniObjClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Object");
  jniClassClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Class");

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  for (lo = 0; lo < args_len; lo++) {
    arg_obj = (*my_jnienv)->GetObjectArrayElement(my_jnienv, args, lo);
    
    jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniObjClass, "getClass", "()Ljava/lang/Class;");
    tmp_obj = (*my_jnienv)->CallObjectMethod(my_jnienv, arg_obj, jniMethodID);
    
    jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniClassClass, "getName", "()Ljava/lang/String;");
    tmp_obj2 = (*my_jnienv)->CallObjectMethod(my_jnienv, tmp_obj, jniMethodID);
    className = (*my_jnienv)->GetStringUTFChars(my_jnienv, tmp_obj2, NULL);
    
    for (src = (char *) className, dst = arg_type; *src; src++, dst++)
      if (*src == '.')
	*dst = '/';
      else
	*dst = *src;

    *dst = '\0';

    if (!strcmp(arg_type, "java/lang/Boolean")) {
      jniIntClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Boolean");
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniIntClass, "booleanValue", "()Z");
      arg_int = (*my_jnienv)->CallBooleanMethod(my_jnienv, arg_obj, jniMethodID) ? 1 : 0;
      XPUSHs(sv_2mortal(newSViv(arg_int)));
    } else if (!strcmp(arg_type, "java/lang/Integer")) {
      jniIntClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Integer");
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniIntClass, "intValue", "()I");
      arg_int = (*my_jnienv)->CallIntMethod(my_jnienv, arg_obj, jniMethodID);
      XPUSHs(sv_2mortal(newSViv(arg_int)));
    } else if (!strcmp(arg_type, "java/lang/Double")) {
      jniDblClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Double");
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniDblClass, "doubleValue", "()D");
      arg_double = (*my_jnienv)->CallDoubleMethod(my_jnienv, arg_obj, jniMethodID);
      XPUSHs(sv_2mortal(newSVnv(arg_double)));
    } else if (!strcmp(arg_type, "java/lang/String")) {
      arg_str = (*my_jnienv)->GetStringUTFChars(my_jnienv, arg_obj, NULL);
      XPUSHs(sv_2mortal(newSVpv(arg_str, 0)));
      (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, arg_obj, arg_str);
    } else {
      arg_pobj = (PerlDroid *)safemalloc(sizeof(PerlDroid));
      java_class_to_perl_obj(arg_type, parg_type);
      arg_pobj->jobj  = arg_obj;
      arg_pobj->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, arg_pobj->jobj);
      psigs = get_sv(parg_type, FALSE);
      arg_pobj->sigs = newSVsv(psigs);
      arg_pobj->class = strdup(parg_type);
      arg_sv = sv_newmortal();
      sv_setref_pv(arg_sv, "PerlDroidPtr", (void*)arg_pobj);
      XPUSHs(sv_2mortal(arg_sv));
    }
  }

  PUTBACK;
  
  count = call_sv((SV *)sub, G_SCALAR);
  
  SPAGAIN;

  if (count != 1) {
    puts("Callback must return one scalar!");
    exit(1);
  }
  
  ret = POPs;

  if (!SvOK(ret)) {
    ret_obj = NULL;
  } else if (SvROK(ret) && SvTYPE(SvRV(ret)) == SVt_PVMG) {
    tmp_param = SvIV((SV*)SvRV(ret));
    pd_param = INT2PTR(PerlDroid *, tmp_param);
    ret_obj = pd_param->jobj;
  } else if (SvIOKp(ret)) {
    jniClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Integer");
    jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", "(I)V");
    ret_obj = (*my_jnienv)->NewObject(my_jnienv, jniClass, jniConstructorID, SvIV(ret));
  } else if (SvNOKp(ret)) {
    jniClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Double");
    jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", "(D)V");
    ret_obj = (*my_jnienv)->NewObject(my_jnienv, jniClass, jniConstructorID, SvNV(ret));
  } else if (SvPOKp(ret)) {
    jniClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/String");
    jniConstructorID = (*my_jnienv)->GetMethodID(my_jnienv, jniClass, "<init>", "(Ljava/lang/String;)V");
    ret_obj = (*my_jnienv)->NewObject(my_jnienv, jniClass, jniConstructorID, (*my_jnienv)->GetStringUTFChars(my_jnienv, SvPV_nolen(ret), NULL));
  } else {
    puts("Return type not recognized");
    exit(1);
  }
  
  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret_obj;
}

jint register_perl(JNIEnv *env, jclass clazz, jstring class)
{
  const char *class_name;
  char buf[128];
  int lo;

  my_jnienv = env;

  JNINativeMethod my_methods[] = {
    { "perl_run", "(Ljava/lang/Object;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I", (void *) run_perl },
    { "perl_callback", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;", (void *) run_callback },
  };
  
  jint result = 0;

  class_name = (*my_jnienv)->GetStringUTFChars(my_jnienv, class, NULL);
  for (lo = 0; lo <= strlen(class_name); lo++)
    if (class_name[lo] == '.')
      buf[lo] = '/';
    else
      buf[lo] = class_name[lo];
  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, class, class_name);

  if (jniRegisterNativeMethods(env, buf, my_methods, NELEM(my_methods))) {
    goto bail;
  }
    
  result = 1;

 bail:
  return result;
}

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
  JNINativeMethod my_methods[] = {
    { "perl_chmod", "(Ljava/lang/String;)V", (void *) run_chmod },
    { "perl_register", "(Ljava/lang/String;)I", (void *) register_perl },
  };
  
  jint result = -1;
  JNIEnv* env = NULL;
  
  if ((*vm)->GetEnv(vm, (void **) &env, JNI_VERSION_1_6) != JNI_OK) {
    goto bail;
  }

  if (jniRegisterNativeMethods(env, CLASSNAME, my_methods, NELEM(my_methods))) {
    goto bail;
  }
    
  result = JNI_VERSION_1_6;

 bail:
  return result;
}
