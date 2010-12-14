package Defaults;

our $RSS_FEED_URL = 'http://hudson:8090/job/Genome/rssAll';
our $BUILD_PATH = '/gsc/scripts/opt/genome/snapshots/unstable';
our $TESTED_PATH = '/gsc/scripts/opt/genome/snapshots/tested';
our $STABLE_PATH = '/gsc/scripts/opt/genome/snapshots/stable';
our $SNAPSHOT_PATH = $ENV{HOME} . '/.hudson_snapshot';

our $UR_REPOSITORY = 'git://github.com/sakoht/UR.git';
our $WORKFLOW_REPOSITORY = 'ssh://git.gsc.wustl.edu/srv/git/workflow.git';
our $GENOME_REPOSITORY = 'ssh://git.gsc.wustl.edu/srv/git/genome.git';
