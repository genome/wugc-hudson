package Snapshot;

use strict;
use warnings;

require Library;
require Defaults;
require File::Path;
require File::Slurp;

sub new {
    my $class = shift;
	my (%params) = @_;
	my $snapshot_dir = delete $params{snapshot_dir} || die;
	my $source_dirs = delete $params{source_dirs} || die;
	my $revisions = delete $params{revisions};
	my $overwrite = delete $params{overwrite};

	if (my @params_keys = keys %params) {
		die "Invalid params passed to Snapshot->new: '" . join(', ', @params_keys) . "'\n";
	}

    my $self = {
        snapshot_dir => $snapshot_dir,
		source_dirs => $source_dirs,
		revisions => $revisions,
		overwrite => $overwrite,
    };

    bless $self, $class;
    return $self;
}

sub open {
	my $class = shift;
	my $snapshot_dir = shift;
	my @source_dirs = File::Slurp::read_file("$snapshot_dir/source_dirs.txt") if (-s "$snapshot_dir/source_dirs.txt");
	my @revisions = File::Slurp::read_file("$snapshot_dir/revisions.txt") if (-s "$snapshot_dir/revisions.txt");
	my (%revisions) = map { split(" ", $_) } @revisions;
	return $class->new(snapshot_dir => $snapshot_dir, source_dirs => \@source_dirs, revisions => \%revisions);
}

sub create {
	my $class = shift;
	
	my $self;
	if ( ref $class ) {
		$self = $class;
	} else {
		$self = $class->new(@_);
	}
	
	my $snapshot_dir = $self->{snapshot_dir};
	my @source_dirs = @{ $self->{source_dirs} };
	
	for my $source_dir (@source_dirs) {
		unless ( -d $source_dir ) {
			die "Error: $source_dir is not a directory.\n";
		}
	}
	
	if ( -d $snapshot_dir ) {
		if ($self->{overwrite}) {
			unless ( File::Path::rmtree($snapshot_dir) ) {
				die "Error: failed to remove $snapshot_dir.\n";
			}
		} else {
			die "Error: $snapshot_dir already exists and overwrite was not specified.\n";
		}
	}
	
	unless ( File::Path::mkpath($snapshot_dir) ) {
		die "Error: failed to create $snapshot_dir.\n";
	}
	
	unless ( File::Slurp::write_file("$snapshot_dir/source_dirs.txt", join("\n", @source_dirs)) ) {
		die "Error: failed to write $snapshot_dir/source_dirs.txt.\n";
	}
	
	my @revisions;
	for my $source_dir (@source_dirs) {
		my $origin_name = qx[$Defaults::GIT_BIN remote -v  | head -n 1 | awk '{print $2}' | sed -e 's/.*\///' -e 's/\.git//'];
		my $origin_hash = qx[$Defaults::GIT_BIN log | head -n 1 | awk '{print $2}'];
		push @revisions, "$origin_name $origin_hash";
	}
	my (%revisions) = map { split(" ", $_) } @revisions;
	$self->{revisions} = \%revisions;
	unless ( File::Slurp::write_file("$snapshot_dir/revisions.txt", join("\n", @revisions)) ) {
		die "Error: failed to write $snapshot_dir/revisions.txt.\n";
	}
	
	for my $source_dir (@source_dirs) {
        my $exit = system("rsync -rltoD --exclude .git $source_dir/ $snapshot_dir/");
		unless ( $exit == 0 ) {
			die "Error: failed to rsync $source_dir.\n";
		}
	}
	
	my @paths = glob("$snapshot_dir/lib/*");
	@paths = grep { $_ !~ /\/lib\/(?:perl|java)\// } @paths;
	for my $path (@paths) {
		(my $new_path = $path) =~ s/\/lib\//\/lib\/perl\//;
		rename($path, $new_path);
	}
	
	return 1;
}

sub announce {
	my $self = shift;
}

sub promote {
	my $self = shift;
	my $snapshot_dir = $self->{snapshot_dir};
	
	if ( $snapshot_dir =~ /$Defaults::UNSTABLE_PATH/ ) {
		(my $new_snapshot_dir = $snapshot_dir) =~ s/$Defaults::UNSTABLE_PATH/$Defaults::TESTED_PATH/;
		return rename($snapshot_dir, $new_snapshot_dir);
	}
	if ( $snapshot_dir =~ /$Defaults::TESTED_PATH/ ) {
		(my $new_snapshot_dir = $snapshot_dir) =~ s/$Defaults::TESTED_PATH/$Defaults::STABLE_PATH/;
		return rename($snapshot_dir, $new_snapshot_dir);
	}
	
	die "Error: tried to promote a directory is not in unstable nor tested path.\n";
}

sub symlink {
	my $self = shift;
}

sub hotfix {
	my $self = shift;
}

1;