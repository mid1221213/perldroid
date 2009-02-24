#include <stdio.h>
#include <stdlib.h>
#include <EXTERN.h>               /* from the Perl distribution     */
#include <perl.h>                 /* from the Perl distribution     */
#include <XSUB.h>
#include <dlfcn.h>

static PerlInterpreter *my_perl;  /***    The Perl interpreter    ***/

static void *lp_h;

void (*my_Perl_sys_init)(int*, char***);
PerlInterpreter* (*my_perl_alloc)(void);
int (*my_perl_construct)(pTHX);
int (*my_perl_destruct)(pTHX);
int (*my_perl_parse)(pTHXx_ XSINIT_t, int, char **, char **);
int (*my_perl_run)(pTHXx);
SV* (*my_Perl_eval_pv)(pTHX_ const char *, I32);
void (*my_Perl_sys_term)(void);
void (*my_perl_free)(pTHXx);
SV* (*my_Perl_get_sv)(pTHX_ const char *, I32);
IV (*my_Perl_sv_2iv_flags)(pTHX_ SV*, I32);
CV* (*my_Perl_newXS)(pTHX_ const char*, XSUBADDR_t, const char*);
U8* (*my_Perl_Iexit_flags_ptr)(void *);
perl_key* (*my_Perl_Gthr_key_ptr)(void *);
void (*my_boot_DynaLoader)(pTHX_ CV* cv);

int open_libperl_so(void)
{
  lp_h = dlopen("/sdcard/org.gtmp.perl/lib/libperl.so", RTLD_LAZY);
  printf("lp_h=%d\n", lp_h);
  
  if (lp_h) {
    my_Perl_sys_init           = dlsym(lp_h, "Perl_sys_init");
    my_perl_alloc              = dlsym(lp_h, "perl_alloc");
    my_perl_construct          = dlsym(lp_h, "perl_construct");
    my_perl_destruct           = dlsym(lp_h, "perl_destruct");
    my_perl_parse              = dlsym(lp_h, "perl_parse");
    my_perl_run                = dlsym(lp_h, "perl_run");
    my_Perl_eval_pv            = dlsym(lp_h, "Perl_eval_pv");
    my_perl_free               = dlsym(lp_h, "perl_free");
    my_Perl_sys_term           = dlsym(lp_h, "Perl_sys_term");
    my_Perl_get_sv             = dlsym(lp_h, "Perl_get_sv");
    my_Perl_sv_2iv_flags       = dlsym(lp_h, "Perl_sv_2iv_flags");
    my_Perl_newXS              = dlsym(lp_h, "Perl_newXS");
    my_Perl_Iexit_flags_ptr    = dlsym(lp_h, "Perl_Iexit_flags_ptr");
    my_Perl_Gthr_key_ptr       = dlsym(lp_h, "Perl_Gthr_key_ptr");
    my_boot_DynaLoader         = dlsym(lp_h, "boot_DynaLoader");
  } else {
    puts(dlerror());
    return 0;
  }

  return 1;
}

void close_libperl_so(void)
{
  dlclose(lp_h);
}

static void xs_init(pTHX);

#define Perl_get_sv my_Perl_get_sv
#define Perl_sv_2iv_flags my_Perl_sv_2iv_flags
#define Perl_newXS  my_Perl_newXS
#define Perl_Gthr_key_ptr my_Perl_Gthr_key_ptr
#define Perl_Iexit_flags_ptr my_Perl_Iexit_flags_ptr

EXTERN_C void
xs_init(pTHX)
{
  char *file = __FILE__;
  /* DynaLoader is a special case */
  newXS("DynaLoader::boot_DynaLoader", my_boot_DynaLoader, file);
}

int
main(int argc_lc, char **argv_lc, char **env_lc)
{
  int ret = -1;
  int argc = 3;
  char ebuf[255];
  char *argv[] = { "org.gtmp.perl", "-MFile::Glob", "-e", "0" };

  if (open_libperl_so()) {
    puts("library open");
    sprintf(ebuf, "$a = %d + %d", 5, 4);
    puts("sprintf done");
    
    my_Perl_sys_init(&argc, (char ***) &argv);
    puts("sys_init OK");
    my_perl = my_perl_alloc();
    puts("alloc OK");
    my_perl_construct(my_perl);
    puts("construct OK");    
    my_perl_parse(my_perl, xs_init, 4, argv, NULL);
    puts("parse OK");
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    puts("exit OK");
    my_perl_run(my_perl);
    puts("run OK");
    
    my_Perl_eval_pv(my_perl, ebuf, TRUE);
    puts("eval OK");

    ret = SvIV(get_sv("a", FALSE));
    puts("get_sv OK");
    printf("ret=%d\n", ret);
    
    my_perl_destruct(my_perl);
    puts("destruct OK");
    my_perl_free(my_perl);
    puts("free OK");
    my_Perl_sys_term();
    puts("sys_term OK");

    close_libperl_so();
    puts("close libperl OK");
  }

  exit(ret);
}
