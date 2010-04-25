package TileView;

use strict;
use base qw/JavaDroid/;
use PerlDroid::android::view;
use PerlDroid::android::graphics;
use Data::Dumper;

our $ARGB_8888 = 3; # fields not implemented :-(

sub set_array2
{
    my ($array_a, $nb) = @_;

    push @$array_a, [] for 1..$nb;
}

sub new
{
    my ($pkg, @rest) = @_;
    my $cpkg = pop(@rest);
    $cpkg ||= $pkg;

    my $self = JavaDroid->new($cpkg, $View, 'org.gtmp.perl.ViewInterface', @rest);

    $self->set_attrs(
	{
	    mTileSize => 12,
	    
	    mXTileCount => 0,
	    mYTileCount => 0,
	    
	    mXOffset => 0,
	    mYOffset => 0,
	    
	    mTileArray => [],

	    mTileGrid => [],

	    mPaint => $Paint->new,
	}
	);

    return $self;
}

sub resetTiles
{
    my ($self, $tilecount) = @_;

    $self->{mTileArray} = [];
}

## Override
sub onSizeChanged
{
    my ($self, $w, $h, $oldw, $oldh) = @_;

    $self->set_attrs(
	{
	    mXTileCount => int($w / $self->{mTileSize}),
	    mYTileCount => int($h / $self->{mTileSize}),
	}
	);
    $self->set_attrs(
	{
	    
	    mXOffset => (($w - ($self->{mTileSize} * $self->{mXTileCount})) / 2),
	    mYOffset => (($h - ($self->{mTileSize} * $self->{mYTileCount})) / 2),
	    
	    mTileGrid => set_array2([], $self->{mYTileCount}),
	}
	);

    $self->clearTiles();
}

sub loadTile
{
    my ($self, $key, $tile) = @_;

    my $bitmap = $Bitmap->createBitmap($self->{mTileSize}, $self->{mTileSize}, $Bitmap_Config->valueOf('ARGB_8888'));
    my $canvas = $Canvas->new($bitmap);

    $tile->setBounds(0, 0, $self->{mTileSize}, $self->{mTileSize});
    $tile->draw($canvas);

    $self->{mTileArray}[$key] = $bitmap;
}

sub clearTiles
{
    my ($self) = @_;

    for (my $x = 0; $x < $self->{mXTileCount}; $x++) {
	for (my $y = 0; $y < $self->{mYTileCount}; $x++) {
	    $self->setTile(0, $x, $y);
	}
    }
}

sub setTile
{
    my ($self, $tileindex, $x, $y) = @_;

    $self->{mTileGrid}[$x][$y] = $tileindex;
}

## Override
sub onDraw
{
    my ($self, $canvas) = @_;

    $self->super($canvas);

    for (my $x = 0; $x < $self->{mXTileCount}; $x++) {
	for (my $y = 0; $y < $self->{mYTileCount}; $x++) {
	    if ($self->{mTileGrid}[$x][$y] > 0) {
		$canvas->drawBitmap($self->{mTileArray}[$self->{mTileGrid}[$x][$y]],
				    $self->{mXOffset} + $x * $self->{mTileSize},
				    $self->{mYOffset} + $y * $self->{mTileSize},
				    $self->{mPaint});
	    }
	}
    }
}

1;
