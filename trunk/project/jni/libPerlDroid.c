#include "JNIHelp.h"
#include <stdio.h>
#include <stdlib.h>
#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
#include <dlfcn.h>
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

JNIEnv *my_jnienv;
typedef struct {
  char *class;
  SV *sigs;
  jobject jobj;
  jobject gref;
} PerlDroid;

int
open_libperl_so(void)
{
  lp_h = dlopen("/data/data/org.gtmp.perl/lib/libperl.so", RTLD_LAZY);
  
  if (lp_h) {
    my_Perl_sys_init       = dlsym(lp_h, "Perl_sys_init");
    my_perl_alloc          = dlsym(lp_h, "perl_alloc");
    my_perl_construct      = dlsym(lp_h, "perl_construct");
    my_perl_destruct       = dlsym(lp_h, "perl_destruct");
    my_perl_parse          = dlsym(lp_h, "perl_parse");
    my_perl_run            = dlsym(lp_h, "perl_run");
    my_Perl_eval_pv        = dlsym(lp_h, "Perl_eval_pv");
    my_perl_free           = dlsym(lp_h, "perl_free");
    my_Perl_sys_term       = dlsym(lp_h, "Perl_sys_term");
    my_Perl_get_sv         = dlsym(lp_h, "Perl_get_sv");
    my_Perl_sv_2iv_flags   = dlsym(lp_h, "Perl_sv_2iv_flags");
    my_Perl_sv_2mortal     = dlsym(lp_h, "Perl_sv_2mortal");
    my_Perl_newXS          = dlsym(lp_h, "Perl_newXS");
    my_Perl_safesysmalloc  = dlsym(lp_h, "Perl_safesysmalloc");
    my_Perl_newSVsv        = dlsym(lp_h, "Perl_newSVsv");
    my_Perl_call_sv        = dlsym(lp_h, "Perl_call_sv");
    my_Perl_sv_setref_pv   = dlsym(lp_h, "Perl_sv_setref_pv");
    my_Perl_get_cv         = dlsym(lp_h, "Perl_get_cv");
    my_Perl_push_scope     = dlsym(lp_h, "Perl_push_scope");
    my_Perl_save_int       = dlsym(lp_h, "Perl_save_int");
    my_Perl_markstack_grow = dlsym(lp_h, "Perl_markstack_grow");
    my_Perl_stack_grow     = dlsym(lp_h, "Perl_stack_grow");
    my_Perl_newSViv        = dlsym(lp_h, "Perl_newSViv");
    my_Perl_newSVnv        = dlsym(lp_h, "Perl_newSVnv");
    my_Perl_newSVpv        = dlsym(lp_h, "Perl_newSVpv");
    my_Perl_sv_newmortal   = dlsym(lp_h, "Perl_sv_newmortal");
    my_Perl_sv_2nv         = dlsym(lp_h, "Perl_sv_2nv");
    my_Perl_sv_2pv_flags   = dlsym(lp_h, "Perl_sv_2pv_flags");
    my_Perl_free_tmps      = dlsym(lp_h, "Perl_free_tmps");
    my_Perl_pop_scope      = dlsym(lp_h, "Perl_pop_scope");
    my_boot_DynaLoader     = dlsym(lp_h, "boot_DynaLoader");
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
do_dialog_perl(JNIEnv *env, jclass cls, jobject this)
{
  my_jnienv = env;
  jint ret = -1;
  int argc = 3;
  char ebuf[32768];
  char *argv[] = { "org.gtmp.perl", "-MPerlDroid::android::content", "-e", "0" };
  FILE *file;
  SV *svret;
  SV *pthis, *ppthis, *ppm, *pnm, *pppnm;
  PerlDroid *param;

  if (open_libperl_so()) {
    sprintf(ebuf, " "
"$| = 1; "
"use PerlDroid; "
"use PerlDroid::java::lang; "
"use PerlDroid::android::app; "
"use PerlDroid::android::content; "
"warn 'beginning';"
"sub onClick {"
"  my ($arg1, $arg2) = @_;"
"  print \"arg1=$arg1, arg2=$arg2\\n\";"
"  if ($arg2 == - 1) {"
"    warn 'class1 = ' . $arg1->getClass->getName;"
"    $arg1->cancel;"
"  } else {"
"    warn 'classthis = ' . $this->getClass->getName;"
"    $this->finish;"
"  }"
"}"
"warn 'getting pm';"
"my $pm = PerlDroid::XS_proxy($DialogInterface_OnClickListener);"
"warn 'getting adb';"
"my $adb = $AlertDialog_Builder->new($this); "
"warn \"after constr, adb=$adb\";"
"$adb->setMessage('Salut ma poule !'); "
"warn 'after setMessage';"
"$adb->setPositiveButton('Ok', $pm); "
"warn 'after spb';"
"$adb->setNegativeButton('Dégage', $pm); "
"warn 'after snb';"
"$adb->create; "
"warn 'after create';"
"$adb->show; "
"warn 'after show';"
"#warn 'class = ' . $pm->getClass->getName;\n"
"print \"Ok\n\";"
"1;"
"");

    my_Perl_sys_init(&argc, (char ***) &argv);
    my_perl = my_perl_alloc();
    PL_perl_destruct_level = 1;
    my_perl_construct(my_perl);
    
    my_perl_parse(my_perl, xs_init, 3, argv, NULL);

    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    my_perl_run(my_perl);

    pthis  = get_sv("this", TRUE);
    ppthis = get_sv("PerlDroid::android::content::Context", FALSE);
/*     ppm    = get_sv("pm",   TRUE); */
/*     pnm    = get_sv("nm",   TRUE); */
/*     pppnm  = get_sv("PerlDroid::android::content::DialogInterface_OnClickListener", FALSE); */

    param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
    param->sigs  = newSVsv(ppthis);
    param->jobj  = this;
    param->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, param->jobj);
    param->class = strdup("PerlDroid::android::content::Context");
    sv_setref_pv(pthis, "PerlDroidPtr", (void*)param);

/*     param = (PerlDroid *)safemalloc(sizeof(PerlDroid)); */
/*     param->sigs  = newSVsv(pppnm); */
/*     param->jobj  = dl; */
/*     param->class = strdup("PerlDroid::android::content::DialogInterface_OnClickListener"); */
/*     sv_setref_pv(ppm, "PerlDroidPtr", (void*)param); */

/*     param = (PerlDroid *)safemalloc(sizeof(PerlDroid)); */
/*     param->sigs  = newSVsv(pppnm); */
/*     param->jobj  = dl; */
/*     param->class = strdup("PerlDroid::android::content::DialogInterface_OnClickListener"); */
/*     sv_setref_pv(pnm, "PerlDroidPtr", (void*)param); */

    svret = my_Perl_eval_pv(my_perl, ebuf, TRUE);
    ret = SvIV(sv_2mortal(svret));
    
/*     PL_perl_destruct_level = 1; */
/*     my_perl_destruct(my_perl); */
/*     my_perl_free(my_perl); */
/*     my_Perl_sys_term(); */

/*     close_libperl_so(); */
  }

  return ret;
}

jint
run_perl(JNIEnv *env, jclass cls, jobject this, jstring script)
{
  my_jnienv = env;
  jint ret = -1;
  int argc = 2;
  char *argv[3];
  SV *pthis, *ppthis;
  PerlDroid *param;
  const char *script_path;

  if (open_libperl_so()) {
    script_path = (*my_jnienv)->GetStringUTFChars(my_jnienv, script, NULL);
    argv[0] = "org.gtmp.perl";
    argv[1] = (char *) script_path;
    argv[2] = NULL;

    my_Perl_sys_init(&argc, (char ***) &argv);
    my_perl = my_perl_alloc();
    PL_perl_destruct_level = 1;
    my_perl_construct(my_perl);
    
    my_perl_parse(my_perl, xs_init, 2, argv, NULL);

    pthis  = get_sv("this", TRUE);
    ppthis = get_sv("PerlDroid::android::content::Context", FALSE);

    param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
    param->sigs  = newSVsv(ppthis);
    param->jobj  = this;
    param->gref = (*my_jnienv)->NewGlobalRef(my_jnienv, param->jobj);
    param->class = strdup("PerlDroid::android::content::Context");
    sv_setref_pv(pthis, "PerlDroidPtr", (void*)param);

    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    LOGV2("before running %s", script_path);
    ret = my_perl_run(my_perl);

    (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, script, script_path);

    // Don't destruct interpreter because of possible callbacks

/*     PL_perl_destruct_level = 1; */
/*     my_perl_destruct(my_perl); */
/*     my_perl_free(my_perl); */
/*     my_Perl_sys_term(); */

/*     close_libperl_so(); */
  }

  return ret;
}

static void
java_class_to_perl_obj(char *java_class, char *perl_obj)
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
run_callback(JNIEnv *env, jclass clazz, jobject obj, jstring m, jobjectArray args)
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
  const char *className;
  jsize args_len;
  char arg_type[128], parg_type[128];
  int lo;
  int arg_int;
  double arg_double;
  const char *arg_str;
  jobject arg_obj;
  PerlDroid *arg_pobj;
  SV *arg_sv, *psigs;

  my_jnienv = env;

  args_len = (*my_jnienv)->GetArrayLength(my_jnienv, args);

  method = (*my_jnienv)->GetStringUTFChars(my_jnienv, m, NULL);
  sub = get_cv(method, 0);
  (*my_jnienv)->ReleaseStringUTFChars(my_jnienv, m, method);

  jniObjClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Object");
  jniClassClass = (*my_jnienv)->FindClass(my_jnienv, "java/lang/Class");

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  for (lo = 0; lo < args_len; lo++) {
    char *src, *dst;

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

    *(dst) = '\0';

    printf("arg #%d type = %s\n", lo, arg_type);

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
    { "perl_run", "(Landroid/content/Context;Ljava/lang/String;)I", (void *) run_perl },
    { "perl_callback", "(Ljava/lang/Class;Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;", (void *) run_callback },
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
