package SnakeView;

use strict;
use base qw/TileView/;
use R;
use PerlDroid::android::os;
use PerlDroid::android::view;
use Time::HiRes qw/gettimeofday/;

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

sub new
{
    my ($pkg, @rest) = @_;
    my $cpkg = pop(@rest);
    $cpkg ||= $pkg;

    my $self = TileView->new(@rest, $cpkg);

    $self->set_attrs(
	{
	    mDirection => $NORTH,
	    mNextDirection => $NORTH,
	    
	    mScore => 0,
	    mMoveDelay => 600,
	    
	    mLastMove => 0,
	    
	    mStatusText => '',
	    
	    mSnakeTrail => [],
	    mAppleList => [],

	    mRedrawHandler => SnakeView_RefreshHandler->new($self),
	}
	);

    $self->initSnakeView;

    return $self;
}

sub initSnakeView
{
    my ($self) = @_;

    $self->setFocusable(1);

    my $r = $self->getContext->getResources;

    $self->resetTiles(4);
    $self->loadTile($RED_STAR, $r->getDrawable($R{drawable}{redstar}));
    $self->loadTile($YELLOW_STAR, $r->getDrawable($R{drawable}{yellowstar}));
    $self->loadTile($GREEN_STAR, $r->getDrawable($R{drawable}{greenstar}));
}

sub initNewGame
{
    my ($self) = @_;

    $self->{mSnakeTrail} = [];
    $self->{mAppleList} = [];

    push @{$self->{mSnakeTrail}}, { 'x' => 7, 'y' => 7};
    push @{$self->{mSnakeTrail}}, { 'x' => 6, 'y' => 7};
    push @{$self->{mSnakeTrail}}, { 'x' => 5, 'y' => 7};
    push @{$self->{mSnakeTrail}}, { 'x' => 4, 'y' => 7};
    push @{$self->{mSnakeTrail}}, { 'x' => 3, 'y' => 7};
    push @{$self->{mSnakeTrail}}, { 'x' => 2, 'y' => 7};

    $self->addRandomApple;
    $self->addRandomApple;

    $self->{mMoveDelay} = 600;
    $self->{mScore} = 0;
}

sub coordArrayListToArray
{
    my ($self, $cvec) = @_;

    my $count = @$cvec;
    my $rawArray = [];

    for (my $index = 0; $index < $count; $index++) {
	$rawArray->[2 * $index] = $cvec->[$index]{x};
	$rawArray->[2 * $index + 1] = $cvec->[$index]{y};
    }

    return $rawArray;
}

sub saveState
{
    my ($self) = @_;

    my $map = $Bundle->new;
    # $map->putIntArray("mAppleList", coordArrayListToArray($self->{mAppleList}); NO SUPPORT FOR ARRAYS YET
    $map->putInt("mDirection", $self->{mDirection});
    $map->putInt("mNextDirection", $self->{mNextDirection});
    $map->putLong("mMoveDelay", $self->{mMoveDelay});
    $map->putLong("mScore", $self->{mScore});
    # $map->putIntArray("mSnakeTrail", coordArrayListToArray($self->{mSnakeTrail}); NO SUPPORT FOR ARRAYS YET

    return $map;
}


sub coordArrayToArrayList
{
    my ($self, $rawArray) = @_;

    my $coordArrayList = [];

    my $coordCount = @$rawArray;
    for (my $index = 0; $index < $coordCount; $index++) {
	push @$coordArrayList, { 'x' => $rawArray->[$index], 'y' => $rawArray->[$index + 1] };
    }

    return $coordArrayList;
}

sub restoreState
{
    my ($self, $icicle) = @_;

    $self->setMode($PAUSE);

    # $self->{mAppleList} = $self->coordArrayToArrayList($icicle->getIntArray("mAppleList")); NO SUPPORT FOR ARRAYS YET
    $self->{mDirection} = $icicle->getInt("mDirection");
    $self->{mNextDirection} = $icicle->getInt("mNextDirection");
    $self->{mMoveDelay} = $icicle->getLong("mMoveDelay");
    $self->{mScore} = $icicle->getLong("mScore");
    # $self->{mSnakeTrail} = $self->coordArrayToArrayList($icicle->getIntArray("mSnakeTrail")); NO SUPPORT FOR ARRAYS YET
}

## Override
sub onKeyDown
{
    my ($self, $keyCode, $msg) = @_;

    warn "$keyCode == $KEYCODE_DPAD_UP";
    if ($keyCode == $KEYCODE_DPAD_UP) {
	if ($self->{mMode} == $READY || $self->{mMode} == $LOSE) {
	    $self->initNewGame;
	    $self->setMode($RUNNING);
	    $self->update;
	    return 1;
	}
	if ($self->{mMode} == $PAUSE) {
	    $self->setMode($RUNNING);
	    $self->update;
	    return 1;
	}
	if ($self->{mDirection} != $SOUTH) {
	    $self->{mNextDirection} = $NORTH;
	}
	return 1;
    }
    if ($keyCode == $KEYCODE_DPAD_DOWN) {
	if ($self->{mDirection} != $NORTH) {
	    $self->{mNextDirection} = $SOUTH;
	}
	return 1;
    }
    if ($keyCode == $KEYCODE_DPAD_LEFT) {
	if ($self->{mDirection} != $EAST) {
	    $self->{mNextDirection} = $WEST;
	}
	return 1;
    }
    if ($keyCode == $KEYCODE_DPAD_RIGHT) {
	if ($self->{mDirection} != $WEST) {
	    $self->{mNextDirection} = $EAST;
	}
	return 1;
    }

    return $self->super($keyCode, $msg);
}

sub setTextView
{
    my ($self, $newView) = @_;

    $self->{mStatusText} = $newView;
}

sub setMode
{
    my ($self, $newMode) = @_;

    my $oldMode = $self->{mMode};
    $self->{mMode} = $newMode;

    if ($newMode == $RUNNING && $oldMode != $RUNNING) {
	$self->{mStatusText}->setVisibility($INVISIBLE);
	$self->update;
	return;
    }

    warn "in setMode: $self";
    my $res = $self->getContext->getResources;
    my $str = '';
    if ($newMode == $PAUSE) {
	$str = $res->getText($R{string}{mode_pause});
    }
    if ($newMode == $READY) {
	$str = $res->getText($R{string}{mode_ready});
    }
    if ($newMode == $LOSE) {
	$str = $res->getText($R{string}{mode_lose_prefix}) . $self->{mScore} . $res->getText($R{string}{mode_lose_suffix});
    }

    $self->{mStatusText}->setText($str);
    $self->{mStatusText}->setVisibility($VISIBLE);
}

sub addRandomApple
{
    my ($self) = @_;

    my $newCoord;
    my $found = 0;

    while (!$found) {
	my $newX = 1 + rand($self->{mXTileCount} - 2);
	my $newY = 1 + rand($self->{mYTileCount} - 2);
	$newCoord = { 'x' => $newX, 'y' => $newY };

	my $collision = 0;
	my $snakelength = @{$self->{mSnakeTrail}};
	for (my $index = 0; $index < $snakelength; $index++) {
	    if ($self->{mSnakeTrail}[$index]{x} == $newX && $self->{mSnakeTrail}[$index]{y} == $newY) {
		$collision = 1;
		last;
	    }
	}

	$found = !$collision;
    }

    push @{$self->{mAppleList}}, $newCoord;
}

sub update
{
    my ($self) = @_;

    if ($self->{mMode} == $RUNNING) {
	my $now = gettimeofday();

	if ($now - $self->{mLastMove} > $self->{mMoveDelay} * 1000) {
	    $self->clearTiles;
	    $self->updateWalls;
	    $self->updateSnake;
	    $self->updateApples;
	    $self->{mLastMove} = $now;
	}
	$self->{mRedrawHandler}->sleep($self->{mMoveDelay});
    }
}

sub updateWalls
{
    my ($self) = @_;

    for (my $x = 0; $x < $self->{mXTileCount}; $x++) {
	$self->setTile($GREEN_STAR, $x, 0);
	$self->setTile($GREEN_STAR, $x, $self->{mYTileCount} - 1);
    }
    for (my $y = 1; $y < $self->{mYTileCount} - 1; $y++) {
	$self->setTile($GREEN_STAR, 0, $y);
	$self->setTile($GREEN_STAR, $self->{mXTileCount} - 1, $y);
    }
}

sub updateApples
{
    my ($self) = @_;

    $self->setTile($YELLOW_STAR, $_->{x}, $_->{y}) for @{$self->{mAppleList}};

}

sub updateSnake
{
    my ($self) = @_;

    my $growSnake = 0;

    my $head = $self->{mSnakeTrail}[@{$self->{mSnakeTrail}} - 1];
    my $newHead;

    $self->{Direction} = $self->{mNextDirection};
    if ($self->{mDirection} == $EAST) {
	$newHead = { 'x' => $head->{x} + 1, 'y' => $head->{y}};
    } elsif ($self->{mDirection} == $WEST) {
	$newHead = { 'x' => $head->{x} - 1, 'y' => $head->{y}};
    } elsif ($self->{mDirection} == $NORTH) {
	$newHead = { 'x' => $head->{x}, 'y' => $head->{y} - 1};
    } elsif ($self->{mDirection} == $SOUTH) {
	$newHead = { 'x' => $head->{x}, 'y' => $head->{y} + 1};
    } else {
	die "boom";
    }

    if ($newHead->{x} < 1 || $newHead->{y} < 1 || $newHead->{x} > $self->{mXTileCount} - 2 || $newHead->{y} > $self->{mYTileCount} - 2) {
	$self->setMode($LOSE);
	return;
    }

    my $snakelength = @{$self->{mSnakeTrail}};
    for (my $index = 0; $index < $snakelength; $index++) {
	if ($self->{mSnakeTrail}[$index]{x} == $newHead->{x} && $self->{mSnakeTrail}[$index]{y} == $newHead->{y}) {
	    $self->setMode($LOSE);
	    return;
	}
    }

    my $applelength = @{$self->{mAppleList}};
    for (my $index = 0; $index < $applelength; $index++) {
	if ($self->{mAppleList}[$index]{x} == $newHead->{x} && $self->{mAppleList}[$index]{y} == $newHead->{y}) {
	    splice(@{$self->{mAppleList}}, $index, 1);
	    $self->addRandomApple;

	    $self->{mScore}++;
	    $self->{mMoveDelay} = int($self->{mMoveDelay} * 0.9);

	    $growSnake = 1;
	}
    }

    push @{$self->{mSnakeTrail}}, $newHead;

    unless($growSnake) {
	shift @{$self->{mSnakeTrail}};
    }

    $snakelength = @{$self->{mSnakeTrail}};
    for (my $index = 0; $index < $snakelength; $index++) {
	if ($index == $snakelength - 1) {
	    $self->setTile($YELLOW_STAR, $self->{mSnakeTrail}[$index]{x}, $self->{mSnakeTrail}[$index]{y});
	} else {
	    $self->setTile($RED_STAR, $self->{mSnakeTrail}[$index]{x}, $self->{mSnakeTrail}[$index]{y});
	}
    }
}

1;

package SnakeView_RefreshHandler;
use strict;
use base qw/JavaDroid/;
use PerlDroid::android::os;

sub new
{
    my ($pkg, $parent_self, $cpkg) = @_;
    $cpkg ||= $pkg;

    my $self = JavaDroid->implements($pkg, $Handler_Callback);

    return $self->set_attrs(
	{
	    parent_self => $parent_self,
	}
	);
}

## Override
sub handleMessage
{
    my ($self, $msg) = @_;

    $self->{parent_self}->update;
    $self->{parent_self}->invalidate;
}

sub sleep
{
    my ($self, $delayMillis) = @_;

    $self->removeMessages(0);
    $self->sendMessageDelayed($self->obtainMessage(0), $delayMillis);
}

1;
