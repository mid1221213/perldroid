#! /usr/bin/perl -w

use strict;
use XML::Parser;
use Cwd;

my $api_file;
$api_file = shift and -f $api_file or usage();
usage() if @ARGV;
my $target = getcwd . "/target_droid";

die "$target already exists, erase it before..." if -e $target;
mkdir $target;
mkdir "$target/PerlDroid";

our $pkg_name;
our $pkg_fname;
our @pkg_classes;

my $xml = XML::Parser->new(Style => 'Subs');
$xml->parsefile($api_file);


open(OUT, ">$target/PerlDroid.pm");
print OUT '
package PerlDroid;

# Constructor
sub new
{
  return XS_constructor(ref(shift), @_);
}

# for methods
sub AUTOLOAD {
  return XS_method($AUTOLOAD, @_)
}
';
close(OUT);

sub package
{
    my ($expat, $element, %attrs) = @_;

    @pkg_classes = ();

    my $name = $attrs{name};
    print "found package $name\n";
    $pkg_fname = "PerlDroid.$name";
    $pkg_fname =~ s/\./\//g;
    $pkg_name = $pkg_fname;
    $pkg_name =~ s/\//::/g;
    
    # Make dir
    my @pkg_dirs = split('/', $pkg_fname);
    my $cur_dir = "$target/" . shift(@pkg_dirs);
    foreach my $dir (@pkg_dirs) {
	$cur_dir .= "/$dir";
	mkdir $cur_dir;
    }    
}


sub package_
{
    my $make_obj = '';
    my @exports;

    foreach my $class (@pkg_classes) {
	$class =~ s/\./::/g;
	$class =~ /([^:]+)$/;
	my $export = "\$$1";
	push @exports, $export;
	$make_obj .= "our $export = bless {}, '${pkg_name}::$class';\n";
    }

    my $exports = join(' ', @exports);

    open(OUT_PKG, ">$target/$pkg_fname.pm") or die "Can't open $target/$pkg_fname.pm: $!";
    print OUT_PKG "package $pkg_name;\nrequire Exporter;\nour \@ISA = ('Exporter');\nour \@EXPORT = qw($exports);\n{\n    no strict 'refs';\n";

    foreach my $class (@pkg_classes) {
	print OUT_PKG "    *{${pkg_name}::${class}::new} = \&PerlDroid::new;\n    *{${pkg_name}::${class}::AUTOLOAD} = \&PerlDroid::AUTOLOAD;\n";
    }

    print OUT_PKG "}\n$make_obj\n";

    close(OUT_PKG);
}

sub class
{
    my ($expat, $element, %attrs) = @_;

    push @pkg_classes, $attrs{name};
}

sub usage
{
    print "Usage: $0 <Android API XML file>\n";
    exit 0;
}
