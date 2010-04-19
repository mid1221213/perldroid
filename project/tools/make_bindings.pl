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
    print OUTPM "package PerlDroid;\nrequire DynaLoader;\n\@ISA = qw/DynaLoader/;\n\nbootstrap PerlDroid;\n1;\n\n";
    print OUTPM "package PerlDroidPtr;\n\nsub cast\n{\n  return &PerlDroid::XS_cast(\@_);\n}\n\n# for methods\nsub AUTOLOAD\n{\n  my \$name = \$AUTOLOAD;\n  \$name =~ s/.*:://;\n  warn \"AUTOLOAD: \$name, \@_\";\n  return if \$name eq 'DESTROY';\n  return &PerlDroid::XS_method(\$name, \@_)\n}\n\n1;";
    close(OUTPM);

    open(OUTPROXY, ">proxy_classes.list");
}

our $pkg_name;
our $pkg_oname;
our $pkg_fname;
our $pkg_ofname;
our $class_name;
our $jclass_name;
our $meth_name;
our @pkg_classes;
our %static_meths;
our %class_methods;
our %seen_proxy;
our $retval;
our @params;
our $uses;
our %used;
our $parent;
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
} else {
    close(OUTPROXY);
}

sub package
{
    my ($expat, $element, %attrs) = @_;

    @pkg_classes = ();
    %class_methods = ();
    %static_meths = ();

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
	    my $oclass = $class;
	    $class =~ s/\./_/g;
	    $oclass =~ s/\./::/g;
	    push @exports, "\$$class";
	    $make_obj .= "our \$$class = bless {\n";

	    foreach my $meth (keys %{$class_methods{"${pkg_name}::$oclass"}}) {
		if ($meth eq '<parent>') {
		    my $par = $class_methods{"${pkg_name}::$oclass"}{'<parent>'};
		    $make_obj .= "  '<parent>' => '$par',\n" if defined($par) && "${pkg_name}::$class" ne 'PerlDroid::java::lang::Object';
		} else {
		    $make_obj .= "  '$meth' => [ qw{" . join(' ', @{$class_methods{"${pkg_name}::$oclass"}{$meth}}) . "} ],\n";
		}
	    }

	    $make_obj .= "}, '${pkg_name}::$class';\n";
	}

	my $exports = join(' ', @exports);

	open(OUT_PKG, ">$target/$pkg_fname.pm") or die "Can't open $target/$pkg_fname.pm: $!";
	print OUT_PKG "package $pkg_name;\nrequire Exporter;\nour \@ISA = ('Exporter');\nour \@EXPORT = qw($exports);\n\n";

  	foreach my $class (@pkg_classes) {
  	    print OUT_PKG "*${pkg_name}::${class}::new = \\&PerlDroid::XS_constructor;\n";
  	}

	my %mseen;
  	foreach my $class (keys %static_meths) {
	    foreach my $meth (@{$static_meths{$class}}) {
		print OUT_PKG "*${pkg_name}::${class}::$meth = sub { return PerlDroid::XS_static('$meth', shift, \@_); };\n" unless $mseen{"${class}::$meth"}++;
	    }
  	}

	print OUT_PKG "\n$uses\n$make_obj\n1;\n";

	close(OUT_PKG);
    }
}

sub class
{
    my ($expat, $element, %attrs) = @_;

    $parent = $attrs{extends};
    if (defined($parent)) {
	$parent =~ s/\$/_/g;
	$parent =~ s/\./::/g;
	$parent = "PerlDroid::$parent";
    }

    my $name = $attrs{name};
    push @pkg_classes, $name;

    my $oname = $jclass_name = $name;
    $name =~ s/\./\$/g;
    $jclass_name =~ s/\./_/g;

    $java2jni->{"$pkg_oname.$oname"} = "L$pkg_ofname/$name;" if $pass == 1;

    $name =~ s/\$/::/g;
    $class_name = "${pkg_name}::$name";

    $uses = '';
    %used = ();
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

    $retval = cjava2jni($attrs{'return'}) || 'V' if $pass == 2;
    $meth_name = $attrs{name};
    @params = ();

    if ($pass == 2 && $retval =~ /^\[*L(.*);$/) {
	my $to_use = $1;
	$to_use =~ s/\/[^\/]+$//g;
	$to_use =~ s/\//::/g;
	$to_use = "PerlDroid::$to_use";
	$uses .= "use $to_use;\n" unless $used{$to_use}++ || $to_use eq $pkg_name;
    }

    if ($attrs{static} eq 'true') {
	push @{$static_meths{$jclass_name}}, $meth_name;
    }

    print OUTPROXY "$class_name\n" if $pass == 2 && !$seen_proxy{$class_name}++ && $meth_name =~ /^on.+/;
}

sub interface
{
    class(@_);
}

sub method_
{
    push @{$class_methods{$class_name}{$meth_name}}, "(" . join('', @params) . ")$retval" if $pass == 2;
    $class_methods{$class_name}{'<parent>'} = $parent if $pass == 2;
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
