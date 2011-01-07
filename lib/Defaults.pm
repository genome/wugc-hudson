package Defaults;

sub BSUB_EMAIL_TO { return 'nnutter@genome.wustl.edu'};
sub ANNOUNCE_EMAIL_TO { return 'apipe@genome.wustl.edu'};

sub GIT_BIN { return '/gsc/bin/git'};

sub RSS_FEED_URL { return 'http://hudson.gsc.wustl.edu/job/Genome/rssAll'};

sub HUDSON_DB { return '/gsc/var/cache/testsuite/hudson.db'};

my $BASE_DIR = '/gsc/scripts/opt/genome';
sub BASE_DIR { return $BASE_DIR };
sub BIN_DIR { return $BASE_DIR . '/bin'};
sub UNSTABLE_PATH { return $BASE_DIR . '/snapshots/unstable'};
sub OLD_PATH { return $BASE_DIR . '/snapshots/old'};
sub TESTED_PATH { return $BASE_DIR . '/snapshots/tested'};
sub STABLE_PATH { return $BASE_DIR . '/snapshots/stable'};
sub CUSTOM_PATH { return $BASE_DIR . '/snapshots/custom'};
sub CURRENT_PIPELINE { return $BASE_DIR . '/current/pipeline'};
sub CURRENT_WEB { return $BASE_DIR . '/current/web'};
sub CURRENT_USER { return $BASE_DIR . '/current/user'};

sub UR_REPOSITORY { return 'git://github.com/sakoht/UR.git'};
sub WORKFLOW_REPOSITORY { return 'ssh://git.gsc.wustl.edu/srv/git/workflow.git'};
sub GENOME_REPOSITORY { return 'ssh://git.gsc.wustl.edu/srv/git/genome.git'};

sub GIT_REPOS_BASE { return '/gscuser/jlolofie/.hudson_repos'};
sub REPOSITORIES {
    return (
    	UR => 'git://github.com/sakoht/UR.git',
    	genome => 'ssh://git.gsc.wustl.edu/srv/git/genome.git',
    	workflow => 'ssh://git.gsc.wustl.edu/srv/git/workflow.git',
    );
};

1;
