#! /usr/bin/perl -w

use strict;
use XML::Parser;
use Cwd;
use Data::Dumper;

my $api_file;
$api_file = shift and -f $api_file or usage();
my $pass = shift;
usage() if @ARGV;
usage() if defined($pass) && $pass !~ /^[12]$/;

my $target = getcwd . "/target_droid";

die "$target already exists, erase it before..." if -e $target;

unless (defined($pass)) {
    system("$0 $api_file 1");
    system("$0 $api_file 2");
    exit(0);
}

if ($pass == 2) {
    mkdir $target;
    mkdir "$target/PerlDroid";

    open(OUTPM, ">$target/PerlDroid.pm");
    print OUTPM "package PerlDroid;\n\n# Constructor\n\nsub new\n{\n  return XS_constructor(ref(shift), \@_);\n}\n\n# for methods\nsub AUTOLOAD {\n  return XS_method(\$AUTOLOAD, \@_)\n}\n";
    close(OUTPM);
}

our $pkg_name;
our $pkg_oname;
our $pkg_fname;
our $pkg_ofname;
our $class_name;
our $meth_name;
our @pkg_classes;
our %class_methods;
our $retval;
our @params;
our $java2jni = {
    ''        => '',
    'void'    => 'V',
    'boolean' => 'Z',
    'byte'    => 'B',
    'char'    => 'C',
    'short'   => 'S',
    'int'     => 'I',
    'long'    => 'J',
    'float'   => 'F',
    'double'  => 'D',
};

our $VAR1;
if ($pass == 2) {
    do "java2jni.pl";
    die $@ if $@;
    $java2jni = $VAR1;
}

my $xml = XML::Parser->new(Style => 'Subs');
$xml->parsefile($api_file);

if ($pass == 1) {
    open(OUTJ2J, ">java2jni.pl");
    print OUTJ2J Dumper($java2jni);
    close(OUTJ2J);
}

sub package
{
    my ($expat, $element, %attrs) = @_;

    @pkg_classes = ();
    %class_methods = ();

    my $name = $pkg_oname = $attrs{name};
    print "$pass: found package $name\n";
    $pkg_ofname = $name;
    $pkg_ofname =~ s/\./\//g;
    $pkg_fname = "PerlDroid/$pkg_ofname";
    $pkg_name = $pkg_fname;
    $pkg_name =~ s/\//::/g;
    
    return if $pass == 1;

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
    if ($pass == 2) {
	my $make_obj = '';
	my @exports;

	foreach my $class (@pkg_classes) {
	    $class =~ s/\./_/g;
	    push @exports, $class;
	    $make_obj .= "our \$$class = bless {\n";

	    foreach my $meth (keys %{$class_methods{"${pkg_name}::$class"}}) {
		$make_obj .= "  '$meth' => [ qw{" . join(' ', @{$class_methods{"${pkg_name}::$class"}{$meth}}) . "} ],\n";
	    }

	    $make_obj .= "}, '${pkg_name}::$class';\n";
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
}

sub class
{
    my ($expat, $element, %attrs) = @_;

    my $name = $attrs{name};
    push @pkg_classes, $name;

    my $oname = $name;
    $name =~ s/\./\$/g;

    $java2jni->{"$pkg_oname.$oname"} = "L$pkg_ofname/$name;" if $pass == 1;

    $name =~ s/\$/::/g;
    $class_name = "${pkg_name}::$name";
}

sub constructor
{
    my ($expat, $element, %attrs) = @_;

    $retval = 'V';
    $meth_name = '<init>';
    @params = ();

}

sub method
{
    my ($expat, $element, %attrs) = @_;

    $retval = cjava2jni($attrs{'return'}) if $pass == 2;
    $meth_name = $attrs{name};
    @params = ();
}

sub interface
{
    class(@_);
}

sub method_
{
    push @{$class_methods{$class_name}{$meth_name}}, "(" . join('', @params) . ")$retval" if $pass == 2;
}

sub constructor_
{
    method_();
}

sub parameter
{
    my ($expat, $element, %attrs) = @_;

    if ($pass == 2) {
	my $param = cjava2jni($attrs{type});
	push @params, $param if $param;
    }
}

sub cjava2jni
{
    my ($in) = @_;
    my $a_dim = '';
    $a_dim .= '[' while $in =~ s/\[\]//g;

    $in =~ s/<.*//;
    $in =~ s/^Progress\.\.\.$//;
    $in =~ s/^Result$//;
    $in =~ s/^Params\.\.\.$//;
    $in =~ s/\.\.\.$//;
    $in =~ s/^[EUTDKVA]$//;
    print "$in\n" if $pass == 2 && !exists($java2jni->{$in});
    my $out = "$a_dim$java2jni->{$in}";

    return $out;
}

sub usage
{
    print "Usage: $0 <Android API XML file>\n";
    exit 0;
}
