#include <JNIHelp.h>
#include <stdio.h>
#include <stdlib.h>
#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
#include <dlfcn.h>

#define CLASSNAME "org/gtmp/perl/PerlDroid"

static PerlInterpreter *my_perl;  /***    The Perl interpreter    ***/
JNIEnv *my_jnienv;

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
CV* (*my_Perl_newXS)(pTHX_ const char*, XSUBADDR_t, const char*);
void (*my_boot_DynaLoader)(pTHX_ CV* cv);

#define Perl_get_sv my_Perl_get_sv
#define Perl_sv_2iv_flags my_Perl_sv_2iv_flags
#define Perl_sv_2mortal my_Perl_sv_2mortal
#define Perl_newXS  my_Perl_newXS
#define Perl_safesysmalloc my_Perl_safesysmalloc
#define Perl_newSVsv my_Perl_newSVsv
#define Perl_sv_setref_pv my_Perl_sv_setref_pv

int
open_libperl_so(void)
{
  lp_h = dlopen("/data/data/org.gtmp.perl/lib/libperl.so", RTLD_LAZY);
  
  if (lp_h) {
    my_Perl_sys_init      = dlsym(lp_h, "Perl_sys_init");
    my_perl_alloc         = dlsym(lp_h, "perl_alloc");
    my_perl_construct     = dlsym(lp_h, "perl_construct");
    my_perl_destruct      = dlsym(lp_h, "perl_destruct");
    my_perl_parse         = dlsym(lp_h, "perl_parse");
    my_perl_run           = dlsym(lp_h, "perl_run");
    my_Perl_eval_pv       = dlsym(lp_h, "Perl_eval_pv");
    my_perl_free          = dlsym(lp_h, "perl_free");
    my_Perl_sys_term      = dlsym(lp_h, "Perl_sys_term");
    my_Perl_get_sv        = dlsym(lp_h, "Perl_get_sv");
    my_Perl_sv_2iv_flags  = dlsym(lp_h, "Perl_sv_2iv_flags");
    my_Perl_sv_2mortal    = dlsym(lp_h, "Perl_sv_2mortal");
    my_Perl_newXS         = dlsym(lp_h, "Perl_newXS");
    my_Perl_safesysmalloc = dlsym(lp_h, "Perl_safesysmalloc");
    my_Perl_newSVsv       = dlsym(lp_h, "Perl_newSVsv");
    my_Perl_sv_setref_pv  = dlsym(lp_h, "Perl_sv_setref_pv");
    my_boot_DynaLoader    = dlsym(lp_h, "boot_DynaLoader");
  } else
    return 0;

  return 1;
}

void
close_libperl_so(void)
{
  dlclose(lp_h);
}

jobject
do_dialog(JNIEnv *env, jclass cls, jobject this, jobject pm, jobject nm) {
  jclass adbClass = (*env)->FindClass(env, "android/app/AlertDialog$Builder");
  jmethodID adbConstructor, spbID, snbID, smsgID, crtID;
  jobject adb;

  if(!adbClass) {
    return NULL;
  }

  adbConstructor = (*env)->GetMethodID(env, adbClass, "<init>", "(Landroid/content/Context;)V");
  if(!adbConstructor) {
    return NULL;
  }

  adb = (*env)->NewObject(env, adbClass, adbConstructor, this);
  if(!adb) {
    return NULL;
  }
  
  smsgID = (*env)->GetMethodID(env, adbClass, "setMessage", "(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;");
  spbID  = (*env)->GetMethodID(env, adbClass, "setPositiveButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;");
  snbID  = (*env)->GetMethodID(env, adbClass, "setNegativeButton", "(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;");
  crtID  = (*env)->GetMethodID(env, adbClass, "create", "()Landroid/app/AlertDialog;");

  (*env)->CallObjectMethod(env, adb, smsgID, (*env)->NewStringUTF(env, "Salut ma poule !"));
  (*env)->CallObjectMethod(env, adb, spbID,  (*env)->NewStringUTF(env, "Ok"), pm);
  (*env)->CallObjectMethod(env, adb, snbID,  (*env)->NewStringUTF(env, "Dégage"), nm);

  return (*env)->CallObjectMethod(env, adb, crtID);
}

EXTERN_C void
xs_init(pTHX)
{
  char *file = __FILE__;
  /* DynaLoader is a special case */
  newXS("DynaLoader::boot_DynaLoader", my_boot_DynaLoader, file);
}

typedef struct {
	char *class;
	SV *sigs;
	jobject jobj;
} PerlDroid;

jint
do_dialog_perl(JNIEnv *env, jclass cls, jobject this, jobject pm, jobject nm) {
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
"use PerlDroid::android::app; "
"use PerlDroid::android::content; "
"warn 'beginning';"
"my $adb = $AlertDialog_Builder->new($this); "
"warn \"after constr, adb=$adb\";"
"$adb->setMessage('Salut ma poule !'); "
"warn 'after setMessage';"
"$adb->setPositiveButton('Ok', $pm); "
"warn 'after spb';"
"$adb->setNegativeButton('Dégage', $nm); "
"warn 'after snb';"
"$adb->create; "
"warn 'after create';"
"$adb->show; "
"warn 'after show';"
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
    ppthis = get_sv("PerlDroid::android::content::DialogInterface_OnClickListener", FALSE);
    ppm    = get_sv("pm",   TRUE);
    pnm    = get_sv("nm",   TRUE);
    pppnm  = get_sv("PerlDroid::android::content::Context", FALSE);

    param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
    param->sigs  = newSVsv(ppthis);
    param->jobj  = this;
    param->class = strdup("PerlDroid::android::content::Context");
    sv_setref_pv(pthis, "PerlDroidPtr", (void*)param);

    param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
    param->sigs  = newSVsv(pppnm);
    param->jobj  = pm;
    param->class = strdup("PerlDroid::android::content::DialogInterface_OnClickListener");
    sv_setref_pv(ppm, "PerlDroidPtr", (void*)param);

    param = (PerlDroid *)safemalloc(sizeof(PerlDroid));
    param->sigs  = newSVsv(pppnm);
    param->jobj  = nm;
    param->class = strdup("PerlDroid::android::content::DialogInterface_OnClickListener");
    sv_setref_pv(pnm, "PerlDroidPtr", (void*)param);

    svret = my_Perl_eval_pv(my_perl, ebuf, TRUE);
    ret = SvIV(sv_2mortal(svret));
    
    PL_perl_destruct_level = 1;
    my_perl_destruct(my_perl);
    my_perl_free(my_perl);
    my_Perl_sys_term();

    close_libperl_so();
  }

  return ret;
}

static jint
run_perl(JNIEnv *env, jclass clazz, jint a, jint b)
{
  my_jnienv = env;
  jint ret = -1;
  int argc = 3;
  char ebuf[255];
  char *argv[] = { "org.gtmp.perl", "-e", "0" };
  FILE *file;
  SV *svret;

  if (open_libperl_so()) {
    //    sprintf(ebuf, "$| = 1;use PerlDroid;use PerlDroid::org::json; my $tst = $JSONException->new('c'); print \"\\$tst=$tst\\n\"; $a = %d + %d; print \"\\$a=$a\\n\";$a", a, b);
    sprintf(ebuf, "$| = 1;use PerlDroid;use PerlDroid::org::json; my $tst = $JSONObject->new($JSONTokener->new('{}')); print \"\\$tst=$tst\\n\"; $a = %d + %d; print \"\\$a=$a\\n\";$a", a, b);

    my_Perl_sys_init(&argc, (char ***) &argv);
    my_perl = my_perl_alloc();
    PL_perl_destruct_level = 1;
    my_perl_construct(my_perl);
    
    my_perl_parse(my_perl, xs_init, 3, argv, NULL);

    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    my_perl_run(my_perl);
    
    svret = my_Perl_eval_pv(my_perl, ebuf, TRUE);
    ret = SvIV(sv_2mortal(svret));
    
    PL_perl_destruct_level = 1;
    my_perl_destruct(my_perl);
    my_perl_free(my_perl);
    my_Perl_sys_term();

    close_libperl_so();
  }

  return ret;
}

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
  JNINativeMethod my_methods[] = {
    { "run_perl", "(II)I", (void *) run_perl },
    { "nativeOnCreateDialog", "(Lorg/gtmp/perl/PerlDroid;Landroid/content/DialogInterface$OnClickListener;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog;", (void *) do_dialog },
    { "perlShowDialog", "(Lorg/gtmp/perl/PerlDroid;Landroid/content/DialogInterface$OnClickListener;Landroid/content/DialogInterface$OnClickListener;)I", (void *) do_dialog_perl },
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
