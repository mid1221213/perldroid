use strict;

$| = 1; 
use PerlDroid;
use PerlDroid::android::content;
use PerlDroid::android::app;

use vars qw/$this/;

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

my $pm = PerlDroid::XS_proxy($DialogInterface_OnClickListener);

my $adb = $AlertDialog_Builder->new($this); 
$adb->setMessage('Salut ma poule !'); 
$adb->setPositiveButton('Ok', $pm); 
$adb->setNegativeButton('Dégage', $pm); 
$adb->create; 
$adb->show; 

print "Ok\n";
warn 'classthis = ' . $this->getClass->getName;
