package Defaults;

our $BSUB_EMAIL_TO = 'nnutter@genome.wustl.edu';
our $ANNOUNCE_EMAIL_TO = 'apipe@genome.wustl.edu';

our $GIT_BIN = '/gsc/bin/git';

our $RSS_FEED_URL = 'http://hudson.gsc.wustl.edu/job/Genome/rssAll';

our $HUDSON_DB = '/gsc/var/cache/testsuite/hudson.db';

our $BASE_DIR 			= '/gsc/scripts/opt/genome';
our $BIN_DIR 			= $BASE_DIR . '/bin';
our $UNSTABLE_PATH 		= $BASE_DIR . '/snapshots/unstable';
our $OLD_PATH 			= $BASE_DIR . '/snapshots/old';
our $TESTED_PATH 		= $BASE_DIR . '/snapshots/tested';
our $STABLE_PATH 		= $BASE_DIR . '/snapshots/stable';
our $CUSTOM_PATH 		= $BASE_DIR . '/snapshots/custom';
our $CURRENT_PIPELINE	= $BASE_DIR . '/current/pipeline';
our $CURRENT_WEB		= $BASE_DIR . '/current/web';
our $CURRENT_USER		= $BASE_DIR . '/current/user';

our $UR_REPOSITORY = 'git://github.com/sakoht/UR.git';
our $WORKFLOW_REPOSITORY = 'ssh://git.gsc.wustl.edu/srv/git/workflow.git';
our $GENOME_REPOSITORY = 'ssh://git.gsc.wustl.edu/srv/git/genome.git';

our $GIT_REPOS_BASE = '/gscuser/jlolofie/.hudson_repos';
our %REPOSITORIES = (
	UR => 'git://github.com/sakoht/UR.git',
	genome => 'ssh://git.gsc.wustl.edu/srv/git/genome.git',
	workflow => 'ssh://git.gsc.wustl.edu/srv/git/workflow.git',
);
