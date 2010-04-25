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
my $itarget = getcwd . "/target_subclasses";
die "$itarget already exists, erase it before..." if -e $itarget;
my $ttarget = getcwd . "/target_tmpl";
die "$ttarget already exists, erase it before..." if -e $ttarget;

unless (defined($pass)) {
    system("$0 $api_file 1");
    system("$0 $api_file 2");
    exit(0);
}

if ($pass == 2) {
    mkdir $target;
    mkdir $itarget;
    mkdir $ttarget;
    mkdir "$target/PerlDroid";

    open(OUTPM, ">$target/PerlDroid.pm");
    print OUTPM "package PerlDroid;\nrequire DynaLoader;\n\@ISA = qw/DynaLoader/;\n\nbootstrap PerlDroid;\n1;\n\n";
    print OUTPM "package PerlDroidPtr;\n\nsub cast\n{\n  return &PerlDroid::XS_cast(\@_);\n}\n\n# for methods\nsub AUTOLOAD\n{\n  my \$name = \$AUTOLOAD;\n  \$name =~ s/.*:://;\n  warn \"AUTOLOAD: \$name, \@_\";\n  return if \$name eq 'DESTROY';\n  return &PerlDroid::XS_method(\$name, 0, \@_)\n}\n\n1;";
    close(OUTPM);
}

our $pkg_name;
our $pkg_oname;
our $pkg_fname;
our $pkg_jname;
our $pkg_ofname;
our $class_name;
our $jclass_name;
our $c_subclasses_name;
our $do_it;
our $call_super;
our $meth_name;
our $cmeth_name;
our @pkg_classes;
our %static_meths;
our %class_methods;
our %class_subclassess;
our ($retval, $iretval);
our (@params, @iparams, @mparams);
our $uses;
our %used;
our $parent;
our %tmpl_struct = ();
our $creating_tmpl = 0;
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
our %to_object = (
    boolean => 'Boolean',
    int     => 'Integer',
    short   => 'Short',
    long    => 'Long',
    char    => 'Character',
    float   => 'Float',
    void    => 'void',
    );

our $VAR1;
if ($pass == 2) {
    do "java2jni.pl";
    die $@ if $@;
    $java2jni = $VAR1;
    do "tmpl_struct.pl";
    die $@ if $@;
    %tmpl_struct = %$VAR1;
}

my $xml = XML::Parser->new(Style => 'Subs');
$xml->parsefile($api_file);

if ($pass == 1) {
    open(OUTJ2J, ">java2jni.pl");
    print OUTJ2J Dumper($java2jni);
    close(OUTJ2J);
    open(OUTTMPL1, ">tmpl_struct.pl");
    print OUTTMPL1 Dumper(\%tmpl_struct);
    close(OUTTMPL1);
}

sub package
{
    my ($expat, $element, %attrs) = @_;

    @pkg_classes = ();
    %class_methods = ();
    %static_meths = ();

    my $name = $pkg_oname = $attrs{name};
    print "$pass: found package $name\n";
    $pkg_ofname = $pkg_jname = $name;
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

sub extends_recurs
{
    my ($name) = @_;

    return 1 if $name =~ /\.?(Activity|Service|ContentProvider|BroadcastReceiver)$/;
    my $pater = $tmpl_struct{$name};
    return extends_recurs($pater) if $pater;
    return 0;
}

sub create_tmpl
{
    my ($name) = @_;

    $creating_tmpl = 1;

    open(OUTTMPL2, ">$ttarget/$name.java") or die "can't create $name.java";
    print OUTTMPL2 "package org.gtmp.perl;\n\npublic class %CLASS% extends $pkg_jname.$name\n{\n";
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

    $creating_tmpl = 0;
    $do_it = $attrs{final} eq 'false' && $attrs{visibility} eq 'public' && $attrs{abstract} eq 'false' && $attrs{deprecated} ne 'deprecated';
#    if ($pkg_jname =~ /^(android\.app|android\.content)$/) {
	if ($pass == 1) {
	    $tmpl_struct{$name} = $attrs{extends} if $do_it;
	} else {
	    create_tmpl($name) if extends_recurs($name);
	}
#    }

    my $oname = $jclass_name = $c_subclasses_name = $name;
    $name =~ s/\./\$/g;
    $jclass_name =~ s/\./_/g;

    $java2jni->{"$pkg_oname.$oname"} = "L$pkg_ofname/$name;" if $pass == 1;

    $name =~ s/\$/::/g;
    $class_name = "${pkg_name}::$name";

    $uses = '';
    %used = ();

    $call_super = '';

    %class_subclassess = ();
}

sub class_
{
    if ($pass == 2) {
	if (%class_subclassess) {
	    my $out_dir = "$itarget/org/gtmp/perl/";
	    my $pkg_dir = $pkg_oname;
	    $pkg_dir =~ s/\./\//g;
	    $out_dir .= $pkg_dir;
	    system("mkdir -p $out_dir");
	    open(OUT_SUBCLASSES, ">$out_dir/$c_subclasses_name.java") or die "Can't open $itarget/$c_subclasses_name.java: $!";
	    print OUT_SUBCLASSES "package org.gtmp.perl.$pkg_oname;\n\npublic class $c_subclasses_name extends $pkg_oname.$c_subclasses_name\n{\n";
	    foreach my $subclasses (keys %class_subclassess) {
		if ($call_super) {
		    print OUT_SUBCLASSES $call_super;
		    $call_super = '';
		}
		print OUT_SUBCLASSES join("\n", @{$class_subclassess{$subclasses}});
	    }
	    print OUT_SUBCLASSES "}\n";
	    close(OUT_SUBCLASSES);
	} elsif ($creating_tmpl) {
	    print OUTTMPL2 "}\n";
	    close(OUTTMPL2);
	}
    }
}

sub constructor
{
    my ($expat, $element, %attrs) = @_;

    $retval = 'V';
    $iretval = 'void';
    $meth_name = '<init>';
    $cmeth_name = $attrs{name};
    @params = ();
    @iparams = ();
    @mparams = ();
}

sub method
{
    my ($expat, $element, %attrs) = @_;

    $retval = cjava2jni($attrs{'return'}) || 'V' if $pass == 2;
    $iretval = $attrs{'return'};
    $meth_name = $attrs{name};
    $cmeth_name = $attrs{name};
    @params = ();
    @iparams = ();
    @mparams = ();

    if ($pass == 2 && $retval =~ /^\[*L(.*);$/) {
	my $to_use = $1;
	$to_use =~ s/\/[^\/]+$//g;
	$to_use =~ s/\//::/g;
	$to_use = "PerlDroid::$to_use";
	$uses .= "use $to_use;\n" unless $to_use eq $pkg_name || $used{$to_use}++;
    }

    if ($attrs{static} eq 'true') {
	push @{$static_meths{$jclass_name}}, $meth_name;
    }
}

sub interface
{
    class(@_);
}

sub method_
{
    return if $c_subclasses_name =~ /^(AsyncTask|RemoteCallbackList|SearchManager|SQLiteDatabase|Touch)$/;
    return unless $do_it;

    push @{$class_methods{$class_name}{$meth_name}}, "(" . join('', @params) . ")$retval" if $pass == 2;
    $class_methods{$class_name}{'<parent>'} = $parent if $pass == 2;

    if ($pass == 2 && ($meth_name eq '<init>' || $meth_name =~ /^on.+/)) {
	my $tretval = $to_object{$iretval};
	my $meth_code = '';

	if ($meth_name eq '<init>') {
	    unless ($creating_tmpl) {
		$call_super  = "    public $cmeth_name(" . join(', ', @iparams) . ")\n    {\n";
		$call_super .= "        super(" . join(', ', @mparams) . ");\n";
		$call_super .= "        org.gtmp.perl.BootStrap.perl_callback(this.getClass().getName(), \"$cmeth_name\", new Object[] { " . join(', ', @mparams) . " }, this);\n";
		$call_super .= "    }\n";
		return;
	    }
	} else {
	    if ($call_super) {
		$meth_code .= $call_super;
		$call_super = '';
	    }
	    $meth_code .= "    public $iretval $cmeth_name(" . join(', ', @iparams) . ")\n    {\n";
	}

	if ($tretval) {
	    if ($tretval eq 'void') {
		$meth_code .= "        org.gtmp.perl.BootStrap.perl_callback(this.getClass().getName(), \"$cmeth_name\", new Object[] { " . join(', ', @mparams) . " }, this);\n";
	    } else {
		if ($creating_tmpl) {
		    $meth_code .=  "        $tretval ret, Object ret_perl;\n";
		    $meth_code .=  "        ret = super.$cmeth_name(" . join(', ', @mparams) . ");\n";
		} else {
		    $meth_code .=  "        Object ret_perl;\n";
		}
		$meth_code .=  "        ret_perl = org.gtmp.perl.BootStrap.perl_callback(this.getClass().getName(), \"$cmeth_name\", new Object[] { " . join(', ', @mparams) . " }, this);\n";
		if ($creating_tmpl) {
		    $meth_code .=   "        if (ret_perl == null)\n            return ret;\n";
		}
		$meth_code .=   "        return (($tretval)ret_perl).${iretval}Value();\n";
	    }
	} else {
	    if ($creating_tmpl) {
		$meth_code .=  "        $iretval ret, Object ret_perl;\n";
		$meth_code .=  "        ret = super.$cmeth_name(" . join(', ', @mparams) . ");\n";
	    } else {
		$meth_code .=  "        Object ret_perl;\n";
	    }
	    $meth_code .=  "        ret_perl = org.gtmp.perl.BootStrap.perl_callback(this.getClass().getName(), \"$cmeth_name\", new Object[] { " . join(', ', @mparams) . " }, this);\n";
	    if ($creating_tmpl) {
		$meth_code .=   "        if (ret_perl == null)\n            return ret;\n";
	    }
	    $meth_code .=   "        return ($iretval)ret_perl;\n";
	}
	$meth_code .=  "    }\n";
	
	if ($creating_tmpl) {
	    print OUTTMPL2 $meth_code;
	} else {
	    push @{$class_subclassess{$class_name}}, $meth_code unless $c_subclasses_name =~ /\./;
	}
    }
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
	push @iparams, "$attrs{type} $attrs{name}";
	push @mparams, "$attrs{name}";
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
