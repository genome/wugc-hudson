echo "=> Creating test database..."
TESTDBSERVER_DB_USER="genome"
TESTDBSERVER_DB_PASS="mypassword"
export TESTDBSERVER_URL="https://apipe-test-db.gsc.wustl.edu"

eval "$(test-db database create --bash --owner genome --based-on snapshot-3549)"
if test -z "$TESTDBSERVER_DB_NAME"
then
    echo "Failed to create test database."
    exit 1
else
    echo "Test database: $TESTDBSERVER_DB_NAME"
fi

set -o nounset
export GENOME_DS_GMSCHEMA_SERVER="dbname=${TESTDBSERVER_DB_NAME};host=${TESTDBSERVER_DB_HOST};port=${TESTDBSERVER_DB_PORT}"
export GENOME_DS_GMSCHEMA_LOGIN=$TESTDBSERVER_DB_USER
export GENOME_DS_GMSCHEMA_AUTH=$TESTDBSERVER_DB_PASS
set +o nounset

echo "=> Migrating test database..."
(
    set -o errexit
    cd sqitch/gms
    sqitch config core.pg.host     $TESTDBSERVER_DB_HOST
    sqitch config core.pg.username $TESTDBSERVER_DB_USER
    sqitch config core.pg.password $TESTDBSERVER_DB_PASS
    sqitch config core.pg.db_name  $TESTDBSERVER_DB_NAME
    if ! sqitch status | /bin/grep -q 'Nothing to deploy'
    then
        sqitch deploy
    fi
)
