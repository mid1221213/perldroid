#ifndef PERLDROID_H
#define PERLDROID_H

typedef struct {
  char *jclass;
  char *pclass;
  SV *sigs;
  jobject jobj;
  jobject gref;
} PerlDroid;


static void
java_class_to_perl_obj(char *java_class, char *perl_obj)
{
  char c;
  
  strcpy(perl_obj, "PerlDroid::");
  perl_obj += 11;
  
  while (c = *(java_class++)) {
    switch(c) {
    case '/':
    case '.':
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

static int
perl_obj_to_java_class(char *perl_obj, char *java_class)
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

#endif
