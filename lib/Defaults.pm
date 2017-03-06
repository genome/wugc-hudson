package Defaults;

sub BSUB_EMAIL_TO { return 'apipe-tester@genome.wustl.edu'};

sub GIT_BIN { return '/gsc/bin/git'};

my $BASE_DIR = '/gsc/scripts/opt/genome';
sub BASE_DIR { return $BASE_DIR };
sub DIST_DIR { return $BASE_DIR . '/dist' };
sub BIN_DIR { return $BASE_DIR . '/bin'};
sub SNAPSHOTS_PATH { return $BASE_DIR . '/snapshots'};
sub OLD_PATH { return $BASE_DIR . '/snapshots/old'};
sub CUSTOM_PATH { return $BASE_DIR . '/snapshots/custom'};
sub CURRENT_PIPELINE { return $BASE_DIR . '/current/pipeline'};
sub CURRENT_WEB { return $BASE_DIR . '/current/web'};
sub CURRENT_USER { return $BASE_DIR . '/current/user'};

sub UR_REPOSITORY { return 'git://github.com/sakoht/UR.git'};
sub GENOME_REPOSITORY { return 'ssh://git.gsc.wustl.edu/srv/git/genome.git'};

sub GIT_REPOS_BASE { return '/gscuser/apipe-tester/.hudson_repos'};
sub REPOSITORIES {
    return (
    	UR => 'git://github.com/sakoht/UR.git',
    	genome => 'ssh://git.gsc.wustl.edu/srv/git/genome.git',
    );
};

sub HUDSON_CUSTOM_WORKSPACE { return '/gscuser/apipe-tester/.hudson-workspaces' };

1;
