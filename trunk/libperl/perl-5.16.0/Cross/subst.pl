#! /usr/bin/perl

use strict;
use warnings;

die "Usage: subst.pl <config> <FILE1> [ <FILE2> ... ]" unless @ARGV > 1;

$| = 1;

my %subst = (
    HOME => $ENV{HOME},
    );

my $conf = shift;
print "Reading $conf... ";
open(CONF, $conf) or die "Can't open $conf: $!";

while (<CONF>) {
    chomp;
    next if /^\s*\#/;
    my ($key, $val) = split(/\s*=\s*/) or next;
    (my $val2 = $val) =~ s/\$\(([^\)]+?)\)/$subst{$1}/ge;
    $subst{$key} = $val2 if $key;
}

close(CONF);
print "done\n";

while (my $file = shift) {
    print "Processing $file... ";

    print "already done, skipping\n" if -e "$file.orig";

    open(IN, $file) or die "Can't open $file: $!";
    open(OUT, ">$file.subst") or die "Can't open $file.subst: $!";

    while (<IN>) {
	s/%%%_([^%]+?)_%%%/$subst{$1}/ge;
	print OUT;
    }

    close(IN);
    close(OUT);

    rename $file, "$file.orig"  or die "Can't rename $file to orig: $!";
    rename "$file.subst", $file or die "Can't rename subst to $file: $!";

    chmod 0755, $file if -x "$file.orig";

    print "done\n";
}
