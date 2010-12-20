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
			unless ( execute_on_deploy("rm -rf $snapshot_dir") ) {
				die "Error: failed to remove $snapshot_dir.\n";
			}
		} else {
			die "Error: $snapshot_dir already exists and overwrite was not specified.\n";
		}
	}
	
	$self->create_snapshot_dir;
	
	$self->post_create_cleanup;
	
	$self->update_tab_completion;
	
	return $self;
}

sub create_snapshot_dir {
	my $self = shift;
	my $snapshot_dir = $self->{snapshot_dir};
	my @source_dirs = @{ $self->{source_dirs} };
	
	unless ( execute_on_deploy("mkdir -p $snapshot_dir") ) {
		die "Error: failed to create directory: '$snapshot_dir'.\n";
	}
	
	unless ( File::Slurp::write_file("/gsc/var/cache/testsuite/source_dirs.txt", join("\n", @source_dirs)) ) {
		die "Error: failed to write /gsc/var/cache/testsuite/source_dirs.txt.\n";
	}
	unless ( execute_on_deploy("mv /gsc/var/cache/testsuite/source_dirs.txt $snapshot_dir/source_dirs.txt") ) {
		die "Error: failed to move $snapshot_dir/source_dirs.txt.\n";
	}
	
	my @revisions;
	for my $source_dir (@source_dirs) {
		my $origin_name = qx[cd $source_dir && $Defaults::GIT_BIN remote -v | grep origin | head -n 1 | awk '{print \$2}' | sed -e 's|.*/||' -e 's|\.git.*||'];
		chomp $origin_name;
		my $origin_hash = qx[cd $source_dir && $Defaults::GIT_BIN log | head -n 1 | awk '{print \$2}'];
		chomp $origin_hash;
		push @revisions, "$origin_name $origin_hash";
	}
	my (%revisions) = map { split(" ", $_) } @revisions;
	$self->{revisions} = \%revisions;
	unless ( File::Slurp::write_file("/gsc/var/cache/testsuite/revisions.txt", join("\n", @revisions)) ) {
		die "Error: failed to write /gsc/var/cache/testsuite/revisions.txt.\n";
	}
	unless ( execute_on_deploy("mv /gsc/var/cache/testsuite/revisions.txt $snapshot_dir/revisions.txt") ) {
		die "Error: failed to move $snapshot_dir/revisions.txt.\n";
	}
	
	sleep(5);
	for my $source_dir (@source_dirs) {
		unless ( system("rsync -e ssh -rltoD --exclude .git $source_dir/ deploy:$snapshot_dir/") == 0 ) {
			die "Error: failed to rsync $source_dir.\n";
		}
	}
	
	sleep(5);
	my @dump_files = `find $snapshot_dir -iname '*sqlite3-dump'`;
	for my $sqlite_dump (@dump_files) {
	    my $sqlite_db = $sqlite_dump;
	    chomp $sqlite_db;
	    $sqlite_db =~ s/-dump//;
	    if (-e $sqlite_db) {
	        print "SQLite DB $sqlite_db already exists, skipping";
	    } else {
			print "Updating SQLite DB ($sqlite_db) from dump\n";
	        my $sqlite_path = $ENV{SQLITE_PATH} || 'sqlite3';
	        execute_on_deploy("$sqlite_path $sqlite_db < $sqlite_dump");
	        die "Error: died building sqlite db for $sqlite_dump" if $?;
	    }
	    unless (-e $sqlite_db) {
	        die "Failed to reconstitute $sqlite_dump as $sqlite_db!";
	    }
	}
	
	return 1;
}

sub post_create_cleanup {
	my $self = shift;
	my $snapshot_dir = $self->{snapshot_dir};
	
	my @paths = glob("$snapshot_dir/lib/*");
	@paths = grep { $_ !~ /\/lib\/(?:perl|java)/ } @paths;
	for my $path (@paths) {
		(my $new_path = $path) =~ s/\/lib\//\/lib\/perl\//;
		unless ( execute_on_deploy("mv $path $new_path") ) {
			die "Error: failed to move $path to $new_path.\n";
		}
	}
	
	for my $unwanted_file ('.gitignore', 'Changes', 'INSTALL', 'LICENSE', 'MANIFEST', 'META.yml', 'Makefile.PL', 'README', 'debian', 'doc', 'inc', 't') {
		execute_on_deploy("rm -rf $snapshot_dir/$unwanted_file");
	}
	
	return 1;
}

sub update_tab_completion {
	my $self = shift;
	my $snapshot_dir = $self->{snapshot_dir};

	execute_on_deploy("cd $snapshot_dir/lib/perl && ur update tab-completion-spec Genome\:\:Command");
	execute_on_deploy("cd $snapshot_dir/lib/perl && ur update tab-completion-spec Genome\:\:Model\:\:Tools");
	execute_on_deploy("cd $snapshot_dir/lib/perl && ur update tab-completion-spec UR\:\:Namespace\:\:Command");	
	execute_on_deploy("cd $snapshot_dir/lib/perl && ur update tab-completion-spec Workflow\:\:Command");
	
	return 1;
}

sub promote {
	my $self = shift;
	my $snapshot_dir = $self->{snapshot_dir};
	
	if ( $snapshot_dir =~ /$Defaults::UNSTABLE_PATH/ ) {
		(my $new_snapshot_dir = $snapshot_dir) =~ s/$Defaults::UNSTABLE_PATH/$Defaults::TESTED_PATH/;
		return execute_on_deploy("mv $snapshot_dir $new_snapshot_dir");
	}
	if ( $snapshot_dir =~ /$Defaults::TESTED_PATH/ ) {
		(my $new_snapshot_dir = $snapshot_dir) =~ s/$Defaults::TESTED_PATH/$Defaults::STABLE_PATH/;
		return execute_on_deploy("mv $snapshot_dir $new_snapshot_dir");
	}
	
	die "Error: tried to promote a directory is not in unstable nor tested path.\n";
}

sub execute_on_deploy {
	my $cmd = shift;
	
	unless ( $cmd ) {
		die "No command specified to execute_on_deploy\n";
	}
	
	my $exit = system("ssh deploy.gsc.wustl.edu '$cmd'");
	die "Error: exit code $? for '$cmd'" if $?;
	
	print "Command exited $exit: $cmd\n";
	
	my $rv = 0;
	$rv = 1 if ( $exit == 0 );
	
	return $rv;
}

1;

