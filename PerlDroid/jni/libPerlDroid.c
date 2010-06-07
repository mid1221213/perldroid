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

#define CLASSNAME "org/gtmp/perl/PerlDroid"

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
static int (*my_Perl_call_method)(pTHX_ char* method, I32 flags);
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
static void* (*my_Perl_hv_common_key_len)(pTHX_ HV *hv, const char *key, I32 klen_i32, const int action, SV *val, const U32 hash);
static SV* (*my_Perl_newSV)(pTHX_ STRLEN len);
static HV* (*my_Perl_newHV)(pTHX);
static SV* (*my_Perl_newRV)(pTHX_ SV* sv);
static void (*my_Perl_load_module_nocontext)(U32 flags, SV* name, SV* ver, ...);
static HV* (*my_Perl_gv_stashpv)(pTHX_ const char* name, I32 flags);
static SV* (*my_Perl_sv_bless)(pTHX_ SV* sv, HV* stash);

static void (*my_boot_DynaLoader)(pTHX_ CV* cv);

#define Perl_get_sv my_Perl_get_sv
#define Perl_sv_2iv_flags my_Perl_sv_2iv_flags
#define Perl_sv_2mortal my_Perl_sv_2mortal
#define Perl_newXS  my_Perl_newXS
#define Perl_safesysmalloc my_Perl_safesysmalloc
#define Perl_newSVsv my_Perl_newSVsv
#define Perl_call_sv my_Perl_call_sv
#define Perl_call_method my_Perl_call_method
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
#define Perl_hv_common_key_len my_Perl_hv_common_key_len
#define Perl_newSV my_Perl_newSV
#define Perl_newHV my_Perl_newHV
#define Perl_newRV my_Perl_newRV
#define Perl_load_module_nocontext my_Perl_load_module_nocontext
#define Perl_gv_stashpv my_Perl_gv_stashpv
#define Perl_sv_bless my_Perl_sv_bless

JNIEnv *my_jnienv;

int
open_libperl_so(void)
{
  lp_h = dlopen("/data/data/org.gtmp.perl/lib/libperl.so", RTLD_LAZY);
  
  if (lp_h) {
    my_Perl_sys_init              = dlsym(lp_h, "Perl_sys_init");
    my_perl_alloc                 = dlsym(lp_h, "perl_alloc");
    my_perl_construct             = dlsym(lp_h, "perl_construct");
    my_perl_destruct              = dlsym(lp_h, "perl_destruct");
    my_perl_parse                 = dlsym(lp_h, "perl_parse");
    my_perl_run                   = dlsym(lp_h, "perl_run");
    my_Perl_eval_pv               = dlsym(lp_h, "Perl_eval_pv");
    my_perl_free                  = dlsym(lp_h, "perl_free");
    my_Perl_sys_term              = dlsym(lp_h, "Perl_sys_term");
    my_Perl_get_sv                = dlsym(lp_h, "Perl_get_sv");
    my_Perl_sv_2iv_flags          = dlsym(lp_h, "Perl_sv_2iv_flags");
    my_Perl_sv_2mortal            = dlsym(lp_h, "Perl_sv_2mortal");
    my_Perl_newXS                 = dlsym(lp_h, "Perl_newXS");
    my_Perl_safesysmalloc         = dlsym(lp_h, "Perl_safesysmalloc");
    my_Perl_newSVsv               = dlsym(lp_h, "Perl_newSVsv");
    my_Perl_call_sv               = dlsym(lp_h, "Perl_call_sv");
    my_Perl_call_method           = dlsym(lp_h, "Perl_call_method");
    my_Perl_sv_setref_pv          = dlsym(lp_h, "Perl_sv_setref_pv");
    my_Perl_get_cv                = dlsym(lp_h, "Perl_get_cv");
    my_Perl_push_scope            = dlsym(lp_h, "Perl_push_scope");
    my_Perl_save_int              = dlsym(lp_h, "Perl_save_int");
    my_Perl_markstack_grow        = dlsym(lp_h, "Perl_markstack_grow");
    my_Perl_stack_grow            = dlsym(lp_h, "Perl_stack_grow");
    my_Perl_newSViv               = dlsym(lp_h, "Perl_newSViv");
    my_Perl_newSVnv               = dlsym(lp_h, "Perl_newSVnv");
    my_Perl_newSVpv               = dlsym(lp_h, "Perl_newSVpv");
    my_Perl_sv_newmortal          = dlsym(lp_h, "Perl_sv_newmortal");
    my_Perl_sv_2nv                = dlsym(lp_h, "Perl_sv_2nv");
    my_Perl_sv_2pv_flags          = dlsym(lp_h, "Perl_sv_2pv_flags");
    my_Perl_free_tmps             = dlsym(lp_h, "Perl_free_tmps");
    my_Perl_pop_scope             = dlsym(lp_h, "Perl_pop_scope");
    my_Perl_croak_nocontext       = dlsym(lp_h, "Perl_croak_nocontext");
    my_Perl_warn_nocontext        = dlsym(lp_h, "Perl_warn_nocontext");
    my_Perl_hv_common_key_len     = dlsym(lp_h, "Perl_hv_common_key_len");
    my_Perl_newSV                 = dlsym(lp_h, "Perl_newSV");
    my_Perl_newHV                 = dlsym(lp_h, "Perl_newHV");
    my_Perl_newRV                 = dlsym(lp_h, "Perl_newRV");
    my_Perl_load_module_nocontext = dlsym(lp_h, "Perl_load_module_nocontext");
    my_Perl_gv_stashpv            = dlsym(lp_h, "Perl_gv_stashpv");
    my_Perl_sv_bless              = dlsym(lp_h, "Perl_sv_bless");

    my_boot_DynaLoader            = dlsym(lp_h, "boot_DynaLoader");
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
run_perl(JNIEnv *env, jclass cls, jstring path)
{
  my_jnienv = env;
  jint ret = -1;
  int argc = 3;
  char *argv[4];
  const char *inc_path;
  char include[128];

  if (lp_h)
    return 1;

  if (open_libperl_so()) {
    inc_path = (*my_jnienv)->GetStringUTFChars(my_jnienv, path, NULL);

    sprintf(include, "-I%s", inc_path);

    argv[0] = "org.gtmp.perl";
    argv[1] = include;
    argv[2] = "-e1";
    argv[3] = NULL;

    my_Perl_sys_init(&argc, (char ***) &argv);
    my_perl = my_perl_alloc();
    PL_perl_destruct_level = 1;
    my_perl_construct(my_perl);
    
    my_perl_parse(my_perl, xs_init, argc, argv, NULL);

/*     PL_exit_flags |= PERL_EXIT_DESTRUCT_END; */
    ret = my_perl_run(my_perl);

    (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, path, inc_path);

    /* don't destruct interpreter */
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

#define THISES_SIZE 1024
HV* thises[THISES_SIZE];

static jobject
run_callback(JNIEnv *env, jclass clazz, jstring clazz_name, jstring m, jobjectArray args, jobject this)
{
  dSP;
  I32 count;
  SV *ret;
  IV tmp_param;
  PerlDroid *pd_param;
  jobject tmp_obj, tmp_obj2, tmp_obj3, ret_obj;
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
  SV *pthis, *ppthis;
  PerlDroid *param;
  char clazz_perl[128];
  char clazz_perl2[128];
  char *class_j2p;
  SV *perl_params[128];

  ENTER;
  SAVETMPS;

  my_jnienv = env;

  args_len = (*my_jnienv)->GetArrayLength(my_jnienv, args);

  from_className = (char *)(*my_jnienv)->GetStringUTFChars(my_jnienv, clazz_name, NULL);
  method = (*my_jnienv)->GetStringUTFChars(my_jnienv, m, NULL);

  warn("frompkg=[%s]", from_className);
  if (!strncmp(from_className, "[PKG]", 5)) {
    class_j2p = from_className + 5;
  } else {
    class_j2p = from_className + strlen(from_className);
    while (*class_j2p != '.' && class_j2p > from_className)
      class_j2p--;
    if (*class_j2p == '.')
      class_j2p++;
  }

  strcpy(clazz_perl, class_j2p);
  load_module(PERL_LOADMOD_NOIMPORT, newSVpv(clazz_perl, strlen(clazz_perl)), NULL);
  strcpy(fromPerlPkg, class_j2p);
  strcat(fromPerlPkg, "::");
  strcat(fromPerlPkg, method);

  sub = get_cv(fromPerlPkg, 0);

  if (!sub) {
    warn("Method %s not found", fromPerlPkg);
    return NULL;
  }

  jniObjClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Object");
  jniClassClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Class");

  PUSHMARK(SP);

  if (this) {
    int i, found = FALSE, first_free = -1;
    HV *self = NULL;

    warn("found this=%p", this);
    for (i = 0; i < THISES_SIZE; i++) {
      if (thises[i]) {
	SV **stmp = hv_fetch(thises[i], "<parent>", 8, 0);
	IV itmp = SvIV((SV*)SvRV(*stmp));
	PerlDroid *tmp = INT2PTR(PerlDroid *,itmp);

	warn("found thises[%d]=%p", i, thises[i]);
	if (tmp->jobj == this) {
	  self = thises[i];
	  break;
	}
      } else if (first_free == -1)
	first_free = i;
    }

    if (!self) {
      char *str;

      if (first_free == -1)
	croak("*** No more room for $self");

      warn("not found self");
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniObjClass, "getClass", "()Ljava/lang/Class;");
      tmp_obj = (*my_jnienv)->CallObjectMethod(my_jnienv, this, jniMethodID);
    
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniClassClass, "getSuperclass", "()Ljava/lang/Class;");
      tmp_obj2 = (*my_jnienv)->CallObjectMethod(my_jnienv, tmp_obj, jniMethodID);
    
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniClassClass, "getName", "()Ljava/lang/String;");
      tmp_obj3 = (*my_jnienv)->CallObjectMethod(my_jnienv, tmp_obj2, jniMethodID);
      className = (*my_jnienv)->GetStringUTFChars(my_jnienv, tmp_obj3, NULL);
  
      java_class_to_perl_obj((char *)className, clazz_perl2);

      (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, tmp_obj3, className);

      ppthis = newSVpv("BUG_NO_SIGS", 11);
      pthis  = newSV(0);

      param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
      param->sigs  = newSVsv(ppthis);
      param->jobj  = this;
      param->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, param->jobj);

      param->jclass = strdup(from_className);
      for (str = param->jclass; *str; str++)
	if (*str == '.')
	  *str = '/';
	
      param->pclass = strdup(clazz_perl2);
      sv_setref_pv(pthis, "PerlDroidPtr", (void*)param);

      self = newHV();
      hv_store(self, "<parent>", 8, pthis, 0);
      sv_bless(newRV_inc((SV*)self), gv_stashpv(clazz_perl, 0));
      thises[first_free] = self;
      warn("set thises[%d]=%p", first_free, thises[first_free]);
    }
    
    warn("pushing self");
    XPUSHs(sv_2mortal(newRV_inc((SV*)self)));
  }

  warn("Processing args");
  for (lo = 0; lo < args_len; lo++) {
    warn("Processing arg #%d/%d", lo, args_len);
    arg_obj = (*my_jnienv)->GetObjectArrayElement(my_jnienv, args, lo);
    
    if (arg_obj == NULL) {
      warn("=>NULL");
      XPUSHs(sv_2mortal(newSV(1)));
    } else {
      warn("arg_obj=%p", arg_obj);
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniObjClass, "getClass", "()Ljava/lang/Class;");
      tmp_obj = (*my_jnienv)->CallObjectMethod(my_jnienv, arg_obj, jniMethodID);
      
      warn("tmp_obj=%p", tmp_obj);
      jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniClassClass, "getName", "()Ljava/lang/String;");
      tmp_obj2 = (*my_jnienv)->CallObjectMethod(my_jnienv, tmp_obj, jniMethodID);
      warn("tmp_obj2=%p", tmp_obj2);
      className = (*my_jnienv)->GetStringUTFChars(my_jnienv, tmp_obj2, NULL);
      
      warn("className=%s", className);
      for (src = (char *) className, dst = arg_type; *src; src++, dst++)
	if (*src == '.')
	  *dst = '/';
	else
	  *dst = *src;

      *dst = '\0';

      warn("Processing arg #%d", lo);
      if (!strcmp(arg_type, "java/lang/Boolean")) {
	warn("boolean");
	jniIntClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Boolean");
	jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniIntClass, "booleanValue", "()Z");
	arg_int = (*my_jnienv)->CallBooleanMethod(my_jnienv, arg_obj, jniMethodID) ? 1 : 0;
	XPUSHs(sv_2mortal(newSViv(arg_int)));
      } else if (!strcmp(arg_type, "java/lang/Integer")) {
	warn("integer");
	jniIntClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Integer");
	jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniIntClass, "intValue", "()I");
	arg_int = (*my_jnienv)->CallIntMethod(my_jnienv, arg_obj, jniMethodID);
	XPUSHs(sv_2mortal(newSViv(arg_int)));
      } else if (!strcmp(arg_type, "java/lang/Double")) {
	warn("double");
	jniDblClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Double");
	jniMethodID = (*my_jnienv)->GetMethodID(my_jnienv, jniDblClass, "doubleValue", "()D");
	arg_double = (*my_jnienv)->CallDoubleMethod(my_jnienv, arg_obj, jniMethodID);
	XPUSHs(sv_2mortal(newSVnv(arg_double)));
      } else if (!strcmp(arg_type, "java/lang/String")) {
	warn("string");
	arg_str = (*my_jnienv)->GetStringUTFChars(my_jnienv, arg_obj, NULL);
	XPUSHs(sv_2mortal(newSVpv(arg_str, 0)));
	(*my_jnienv)->ReleaseStringUTFChars(my_jnienv, arg_obj, arg_str);
      } else {
	warn("object");
	arg_pobj = (PerlDroid *)safemalloc(sizeof(PerlDroid));
	java_class_to_perl_obj(arg_type, parg_type);
	arg_pobj->jobj  = arg_obj;
	arg_pobj->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, arg_pobj->jobj);
	psigs = get_sv(parg_type, FALSE);
	arg_pobj->sigs = newSVsv(psigs);
	arg_pobj->jclass = strdup(arg_type);
	arg_pobj->pclass = strdup(parg_type);
	arg_sv = sv_newmortal();
	sv_setref_pv(arg_sv, "PerlDroidPtr", (void*)arg_pobj);
	XPUSHs(sv_2mortal(arg_sv));
      }

      (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, tmp_obj2, className);
    }
  }
  warn("Processed args");

  PUTBACK;
  
  warn("sp=[%p],mark=[%p],base=[%p] => %p, my_perl=%p", sp, *PL_markstack_ptr, PL_stack_base, (sp-((*PL_markstack_ptr) + PL_stack_base)), my_perl);
  count = call_sv((SV *)sub, G_SCALAR);
  warn("sp=[%p],mark=[%p],base=[%p] => %p, my_perl=%p", sp, *PL_markstack_ptr, PL_stack_base, (sp-((*PL_markstack_ptr) + PL_stack_base)), my_perl);
  
  SPAGAIN;

  if (count != 1)
    croak("Callback must return one scalar! (%d/%x)", count, count);
  
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
    croak("Return type not recognized");
  }
  
  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, clazz_name, from_className);
  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, m, method);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret_obj;
}

/* jint register_perl(JNIEnv *env, jclass clazz, jstring class) */
/* { */
/*   const char *class_name; */
/*   char buf[128]; */
/*   int lo; */

/*   my_jnienv = env; */

/*   JNINativeMethod my_methods[] = { */
/*     { "perl_run", "(Ljava/lang/String;)I", (void *) run_perl }, */
/*     { "perl_callback", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;", (void *) run_callback }, */
/*   }; */
  
/*   jint result = 0; */

/*   class_name = (*my_jnienv)->GetStringUTFChars(my_jnienv, class, NULL); */
/*   for (lo = 0; lo <= strlen(class_name); lo++) */
/*     if (class_name[lo] == '.') */
/*       buf[lo] = '/'; */
/*     else */
/*       buf[lo] = class_name[lo]; */
/*   (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, class, class_name); */

/*   if (jniRegisterNativeMethods(env, buf, my_methods, NELEM(my_methods))) { */
/*     goto bail; */
/*   } */
    
/*   result = 1; */

/*  bail: */
/*   return result; */
/* } */

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
  JNINativeMethod my_methods[] = {
    { "perl_chmod", "(Ljava/lang/String;)V", (void *) run_chmod },
    { "perl_callback", "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;", (void *) run_callback },
    { "perl_run", "(Ljava/lang/String;)I", (void *) run_perl },
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
