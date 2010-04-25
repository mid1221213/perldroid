package JavaDroid;

use strict;
use Data::Dumper;

our $AUTOLOAD;

sub AUTOLOAD
{
  my $name = $AUTOLOAD;
  $name =~ s/.*:://;
  warn "AUTOLOAD: $name, @_";
  return if $name eq 'DESTROY';

  warn Dumper(\@_);
  return PerlDroid::XS_method($name, 0, shift->{'<parent>'}, @_);
}

sub super
{
  my $name = (caller(1))[3];
  $name =~ s/.*:://;
  warn "super: $name, @_";

  warn Dumper(\@_);
  return PerlDroid::XS_method($name, 1, shift->{'<parent>'}, @_);
}

sub implements
{
    my ($jpkg, $cpkg, $pobj) = @_;

    return bless {
	'<parent>' => ref($pobj),
	'<perl>'   => 1,
	'<proxy>'  => PerlDroid::XS_implements($pobj, $cpkg),
    }, $cpkg;
}

sub new
{
    my ($jpkg, $cpkg, $pobj, $interf_str, @rest) = @_;

    my $self = $pobj->new(@rest);
    warn "interf_str=$interf_str";
    return bless {
	'<parent>' => PerlDroid::XS_castObj($self, $cpkg),
#	'<parent>' => $self,
	'<perl>'  => 1,
	'<proxy>' => PerlDroid::XS_proxy($interf_str, $cpkg),
    }, $cpkg;
}

sub set_attrs
{
    my ($obj, $hash_p) = @_;

    $obj->{$_} = $hash_p->{$_} for keys %$hash_p;

    return $obj;
}

1;
