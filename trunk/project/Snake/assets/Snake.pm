package Snake;

use strict;
use base qw/JavaDroid/;
use PerlDroid;
use PerlDroid::android::widget;
use PerlDroid::android::app;
use PerlDroid::android::os;
use SnakeView;
use Data::Dumper;
use R;

our $ICICLE_KEY = 'snake-view';

our $PAUSE = 0;
our $READY = 1;
our $RUNNING = 2;
our $LOSE = 3;

our $NORTH = 1;
our $SOUTH = 2;
our $EAST = 3;
our $WEST = 4;


our $RED_STAR = 1;
our $YELLOW_STAR = 2;
our $GREEN_STAR = 3;

our $KEYCODE_DPAD_UP = 19;
our $KEYCODE_DPAD_DOWN = 20;
our $KEYCODE_DPAD_LEFT = 21;
our $KEYCODE_DPAD_RIGHT = 22;

our $VISIBLE = 0;
our $INVISIBLE = 4;

sub onCreate
{
    my ($self, $savedInstanceState) = @_;

    warn "self=$self, sis=$savedInstanceState";
#    $self->super($savedInstanceState);

    if ($savedInstanceState) {
	my $map = $savedInstanceState->getBundle($ICICLE_KEY);
	$self->restoreState($map);
    } else {
 	$self->set_attrs(
 	    {
 		mSnakeView => SnakeView->new($self->{'<parent>'}, undef),
 	    }
 	    );
  	$self->setContentView($self->{mSnakeView});
	$self->{mSnakeView}->setTextView($TextView->new($self->{'<parent>'}));
  	$self->{mSnakeView}->setMode($SnakeView::READY);
    }

    return 0;
}

sub onPause
{
    my ($self) = @_;

    # Pause the game along with the activity
    $self->setMode($SnakeView::PAUSE);

    return 0;
}

sub onSaveInstanceState
{
    my ($self, $outState) = @_;
    # Store the game state
    $outState->putBundle($ICICLE_KEY, $self->saveState);

    return 0;
}

## Override
sub onKeyDown
{
    my ($self, $keyCode, $msg) = @_;

    my $sself = $self->{mSnakeView};

    warn "$keyCode == $KEYCODE_DPAD_UP";
    if ($keyCode == $KEYCODE_DPAD_UP) {
	if ($sself->{mMode} == $READY || $sself->{mMode} == $LOSE) {
	    $sself->initNewGame;
	    $sself->setMode($RUNNING);
	    $sself->update;
	    return 1;
	}
	if ($sself->{mMode} == $PAUSE) {
	    $sself->setMode($RUNNING);
	    $sself->update;
	    return 1;
	}
	if ($sself->{mDirection} != $SOUTH) {
	    $sself->{mNextDirection} = $NORTH;
	}
	return 1;
    }
    if ($keyCode == $KEYCODE_DPAD_DOWN) {
	if ($sself->{mDirection} != $NORTH) {
	    $sself->{mNextDirection} = $SOUTH;
	}
	return 1;
    }
    if ($keyCode == $KEYCODE_DPAD_LEFT) {
	if ($sself->{mDirection} != $EAST) {
	    $sself->{mNextDirection} = $WEST;
	}
	return 1;
    }
    if ($keyCode == $KEYCODE_DPAD_RIGHT) {
	if ($sself->{mDirection} != $WEST) {
	    $sself->{mNextDirection} = $EAST;
	}
	return 1;
    }

    return $self->super($keyCode, $msg);
}

1;
