#include <JNIHelp.h>
#include <stdio.h>
#include <stdlib.h>
#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
#include <dlfcn.h>

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

#define Perl_get_sv my_Perl_get_sv
#define Perl_sv_2iv_flags my_Perl_sv_2iv_flags

int open_libperl_so(void)
{
  lp_h = dlopen("/data/data/org.gtmp.perl/lib/libperl.so", RTLD_LAZY);
  
  if (lp_h) {
    my_Perl_sys_init     = dlsym(lp_h, "Perl_sys_init");
    my_perl_alloc        = dlsym(lp_h, "perl_alloc");
    my_perl_construct    = dlsym(lp_h, "perl_construct");
    my_perl_destruct     = dlsym(lp_h, "perl_destruct");
    my_perl_parse        = dlsym(lp_h, "perl_parse");
    my_perl_run          = dlsym(lp_h, "perl_run");
    my_Perl_eval_pv      = dlsym(lp_h, "Perl_eval_pv");
    my_perl_free         = dlsym(lp_h, "perl_free");
    my_Perl_sys_term     = dlsym(lp_h, "Perl_sys_term");
    my_Perl_get_sv       = dlsym(lp_h, "Perl_get_sv");
    my_Perl_sv_2iv_flags = dlsym(lp_h, "Perl_sv_2iv_flags");
  } else
    return 0;

  return 1;
}

void close_libperl_so(void)
{
  dlclose(lp_h);
}

static jint
run_perl(JNIEnv *env, jclass clazz, jint a, jint b)
{
  jint ret = -1;
  int argc = 3;
  char ebuf[255];
  char *argv[] = { "org.gtmp.perl", "-e", "0" };

  if (open_libperl_so()) {
    sprintf(ebuf, "$a = %d + %d", a, b);
    
    my_Perl_sys_init(&argc, (char ***) &argv);
    my_perl = my_perl_alloc();
    my_perl_construct( my_perl );
    
    my_perl_parse(my_perl, NULL, 3, argv, NULL);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    my_perl_run(my_perl);
    
    my_Perl_eval_pv(my_perl, ebuf, TRUE);
    ret = SvIV(get_sv("a", FALSE));
    
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
