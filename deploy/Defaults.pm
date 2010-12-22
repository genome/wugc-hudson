package Defaults;

our $RSS_FEED_URL = 'http://hudson:8090/job/Genome/rssAll';
our $BUILD_PATH = '/gscuser/jlolofie/.hudson/jobs/Genome/builds';
our $SNAPSHOT_PATH = $ENV{HOME} . '/.hudson_snapshot';
our $GSCPAN = $ENV{GSCPAN} || 'svn+ssh://svn/srv/svn/gscpan';

our $UR_REPOSITORY = 'git://github.com/sakoht/UR.git';
our $WORKFLOW_REPOSITORY = 'ssh://git/srv/git/workflow.git';
our $GENOME_REPOSITORY = 'ssh://git/srv/git/genome.git';

our $UNSTABLE_SNAPSHOT_DIR = '/gsc/scripts/opt/genome/snapshots/unstable/';
our $TESTED_SNAPSHOT_DIR = '/gsc/scripts/opt/genome/snapshots/tested/';
our $STABLE_SNAPSHOT_DIR = '/gsc/scripts/opt/genome/snapshots/stable/';
our $CUSTOM_SNAPSHOT_DIR = '/gsc/scripts/opt/genome/snapshots/custom/';
our $STABLE_SYMLINK = '/gsc/scripts/opt/genome/current/stable';
