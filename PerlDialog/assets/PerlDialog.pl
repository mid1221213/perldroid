$| = 1; 
use PerlDroid;
use PerlDroid::java::lang;
use PerlDroid::android::app;
use PerlDroid::android::content;

use vars qw/$this/;

warn 'beginning';
sub onClick {
  my ($arg1, $arg2) = @_;
  print "arg1=$arg1, arg2=$arg2\n";
  if ($arg2 == - 1) {
    warn 'class1 = ' . $arg1->getClass->getName;
    $arg1->cancel;
  } else {
    warn 'classthis = ' . $this->getClass->getName;
    $this->finish;
  }
}

warn 'getting pm';
my $pm = PerlDroid::XS_proxy($DialogInterface_OnClickListener);

warn 'getting adb';
my $adb = $AlertDialog_Builder->new($this); 

warn "after constr, adb=$adb";
$adb->setMessage('Salut ma poule !'); 

warn 'after setMessage';
$adb->setPositiveButton('Ok', $pm); 

warn 'after spb';
$adb->setNegativeButton('Dégage', $pm); 

warn 'after snb';
$adb->create; 

warn 'after create';
$adb->show; 

warn 'after show';
#warn 'class = ' . $pm->getClass->getName;

print "Ok\n";
