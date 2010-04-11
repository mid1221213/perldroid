use strict;
use R;

$| = 1; 
use PerlDroid;
use PerlDroid::android::content;
use PerlDroid::android::app;
use PerlDroid::android::widget;

use vars qw/$this/;

my $pm = PerlDroid::XS_proxy($DialogInterface_OnClickListener, "PerlDialog::DialogInterface");

my $adb = $AlertDialog_Builder->new($this); 
$adb->setMessage('Salut ma poule !'); 
$adb->setPositiveButton('Ok', $pm); 
$adb->setNegativeButton('Dégage', $pm); 
$adb->create; 
$adb->show; 

print "Ok\n";
warn 'classthis = ' . $this->getClass->getName;
printf("R.layout.main=0x%x\n", $R{layout}{main});
$this->findViewById($R{id}{TV})->cast($TextView)->setText("Mid was here! :-)");

package PerlDialog::DialogInterface;

sub onClick {
    my ($arg1, $arg2) = @_;
    print "arg1=$arg1, arg2=$arg2\n";
    if ($arg2 == - 1) {
	warn 'class1 = ' . $arg1->getClass->getName;
	$arg1->cancel;
    } else {
	warn 'classthis = ' . $main::this->getClass->getName;
	$main::this->finish;
    }
}
