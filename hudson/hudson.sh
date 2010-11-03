#!/bin/bash -x

set -o errexit   # exit if any command fails
set -o pipefail  # fail if any command in a pipe fails
set -o nounset   # fail if an env var is used but unset



if [ -n "${HUDSON_PROJECT_PATH+x}" ]; then
    echo "HUDSON_PROJECT_PATH: $HUDSON_PROJECT_PATH"
else
    echo "Error: HUDSON_PROJECT_PATH not set."
    exit
fi


if [ -n "${CODE_STORAGE_BASE+x}" ]; then
    echo "CODE_STORAGE_BASE: $CODE_STORAGE_BASE"
else
    echo "Error: CODE_STORAGE_BASE not set."
    exit
fi


if [ -e $CODE_STORAGE_BASE/UR ] && [ -e $CODE_STORAGE_BASE/genome ]; then
    echo "./UR and ./GENOME look good"
else
	echo "Erorr: $CODE_STORAGE_BASE is missing /UR or /genome."
	exit
fi


if [ -n "${WORKSPACE+x}" ]; then
	echo "WORKSPACE: $WORKSPACE"
else
	echo "Error: WORKSPACE env variable not set. Run in Hudson."
	exit
fi



export PERL_TEST_HARNESS_DUMP_TAP=$WORKSPACE/test_result
TEST_TOOLS="/gscuser/jlolofie/dev/wugc-hudson/tools/"
GIT_CMD="/gsc/bin/git "
BUILD_NAME="genome-$BUILD_NUMBER"
BUILD_DIR="$HUDSON_PROJECT_PATH/$JOB_NAME/builds/$BUILD_NUMBER"
REV_FILE="$BUILD_DIR/revision.txt"



# delete stuff from the last tests
rm $WORKSPACE/* -rf


i=0
for NAMESPACE in "genome" "UR" "workflow"
do

cd $CODE_STORAGE_BASE/$NAMESPACE
$GIT_CMD reset --hard
$GIT_CMD pull origin master

    if [[ $NAMESPACE = "genome" ]]; then
        $GIT_CMD tag $BUILD_NAME
        $GIT_CMD push origin master --tags
    fi

cd $WORKSPACE
$GIT_CMD clone $CODE_STORAGE_BASE/$NAMESPACE/.git $NAMESPACE
echo -n "$NAMESPACE " >> $REV_FILE

cd $WORKSPACE/$NAMESPACE
HASH=`$GIT_CMD show --oneline --summary | head -n1 | cut -d ' ' -f1`
echo $HASH >> $REV_FILE
GIT_HASH[i]=$HASH
let "i += 1"
done



## record stuff in our sqlitedb
SQLITE_DB="/gsc/var/cache/testsuite/hudson.db"

GENOME_HASH=${GIT_HASH[0]}
UR_HASH=${GIT_HASH[1]}
WORKFLOW_HASH=${GIT_HASH[2]}

NOW=`date +"%Y-%m-%d %H:%M:%S"`
SQL="INSERT INTO unit_test (date, status, build_number, genome_hash, ur_hash, workflow_hash ) \
values (\"$NOW\", \"started\", \"$BUILD_NUMBER\", \"$GENOME_HASH\", \"$UR_HASH\", \"$WORKFLOW_HASH\");"
echo $SQL | sqlite3 $SQLITE_DB
## end - record stuff in our sqlitedb



cd $WORKSPACE/genome/lib/perl/Genome/


/gsc/scripts/sbin/gsc-cron /gsc/bin/perl \
-I $WORKSPACE/UR/lib \
-I $WORKSPACE/genome/lib/perl \
-I $WORKSPACE/workflow/lib \
$WORKSPACE/UR/bin/ur test run \
--lsf-params="-q short -R 'select[type==LINUX64 && model!=Opteron250 && tmp>1000 && mem>4000] rusage[tmp=1000, mem=4000]'" \
--recurse --junit --lsf --jobs=10



# sleep and hope the junit files have been written by now and are accessible in NFS
#sleep 120

#bsub -u jlolofie@genome.wustl.edu -q short perl $TEST_TOOLS/email_failures.pl $BUILD_NUMBER

SQL="UPDATE unit_test SET status = 'done' where BUILD_NUMBER = $BUILD_NUMBER;"
echo $SQL | sqlite3 $SQLITE_DB




