#! /usr/local/bin/perl -w

use strict;
use Archive::Zip qw/:ERROR_CODES :CONSTANTS/;;
use Module::CoreList;
use Cwd;

my @core_mods = keys %{$Module::CoreList::version{5.016}};
my @ldirs = qw,auto linux-androideabi-thread-multi linux-androideabi-thread-multi/auto,;

my $mods_dir;
$mods_dir = shift and -d $mods_dir or usage();
usage() if @ARGV;
my $target_pm = cwd . '/target_core_pm';
my $target_so = cwd . '/target_core_so';

die "$target_pm already exists, erase it before..." if -e $target_pm;
die "$target_so already exists, erase it before..." if -e $target_so;

our ($core_dir, $gldir, %mod_files);
foreach my $core_mod (@core_mods) {
    $core_dir = $core_mod;
    $core_dir =~ s/::/\//g;
    my $mod_files_h = {};
    foreach my $ldir ('', @ldirs) {
	my $f_dir = $ldir ? "$ldir/" : '';
	$mod_files_h->{"$f_dir$core_dir.pm"} = 1 if -f "$mods_dir/$f_dir$core_dir.pm";
	$gldir = $ldir;
	my $ddir = "$mods_dir/$f_dir$core_dir";
	recurs_dir($ddir, $mod_files_h) if -d $ddir;
    }
    $mod_files{$core_mod} = $mod_files_h;
}

foreach my $core_mod (sort { length($b) <=> length($a) } keys %mod_files) {
    foreach my $core_mod_2 (keys %mod_files) {
	next if $core_mod eq $core_mod_2 || length($core_mod_2) > length($core_mod);
	my $core_prefix_2 = $core_mod_2;
	if ($core_mod =~ /^$core_prefix_2/) {
	    $core_prefix_2 =~ s/::/\//g;
	    delete $mod_files{$core_mod_2}{$_} for grep { /$core_prefix_2\// } keys %{$mod_files{$core_mod}}
	}
    }
}

mkdir $target_pm;
mkdir $target_so;
chdir $mods_dir;

foreach my $core_mod (sort keys %mod_files) {
    print "Skipping $core_mod\n", next unless keys %{$mod_files{$core_mod}};
    print "Zipping $core_mod:";
    my $zip_pm = Archive::Zip->new();
    my $zip_so = Archive::Zip->new();
    my $so_nb = 0;
    my @core_files = keys %{$mod_files{$core_mod}};
    push @core_files, 'linux-androideabi-thread-multi/Config_heavy.pl' if $core_mod eq 'Config'; # Special case
    push @core_files, 'utf8_heavy.pl' if $core_mod eq 'utf8'; # Special case
    push @core_files, 'unicore/Heavy.pl' if $core_mod eq 'utf8'; # Special case
    foreach my $file (@core_files) {
	print " $file";
	-f $file or die "$file does not exist";
	if ($file !~ /\.pod$/) {
	    if ($file =~ /\.so$/) {
		$so_nb++;
		$zip_so->addFile($file) or die;
	    } else {
		$zip_pm->addFile($file) or die;
	    }
	}
    }
    print " => $target_pm/$core_mod.zip";
    $zip_pm->writeToFileNamed("$target_pm/$core_mod.zip") == AZ_OK or die "ZIP $target_pm/$core_mod.zip write error";
    if ($so_nb) {
	print " => $target_so/$core_mod.zip\n";
	$zip_so->writeToFileNamed("$target_so/$core_mod.zip") == AZ_OK or die "ZIP $target_so/$core_mod.zip write error";
    } else {
	print "\n";
    }
}
print "\nEnd\n";

sub recurs_dir
{
    my ($ddir, $mod_files_h, $np) = @_;

    if (-d $ddir) {
	opendir(my $dh, $ddir) or die "Can't opendir $ddir";
	foreach my $f_d (grep { !/^\./ } readdir($dh)) {
	    my $ff_d = "$ddir/$f_d";
	    if (-d $ff_d) {
		$f_d = "$np/$f_d" if $np;
		recurs_dir($ff_d, $mod_files_h, $f_d);
	    } else {
		$f_d = "$np/$f_d" if $np;
		$f_d = "$core_dir/$f_d";
		$f_d = "$gldir/$f_d" if $gldir;
		$mod_files_h->{$f_d} = 1;
	    }
	}
	closedir($dh);
    }
}

sub usage
{
    print "Usage: $0 <dir_whith_modules>\n";
    exit 0;
}
